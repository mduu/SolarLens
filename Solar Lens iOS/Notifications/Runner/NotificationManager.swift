import BackgroundTasks
internal import Foundation
import SwiftUI
internal import UserNotifications

/// Runner for the read-only notification monitors (story #5).
///
/// One singleton, an array of active monitors that tick in parallel.
/// Distinct from `AutomationManager` because monitors run alongside
/// each other AND alongside a running controlling automation —
/// see [ADR-002](../../specs/adrs/002-notifications-separate-from-automations.md).
///
/// Wiring summary:
/// - Each monitor carries its own `nextCheckAt`. A foreground timer
///   (60 s) checks every monitor on each tick and re-runs whichever
///   one is overdue.
/// - The BG refresh task identifier is **shared** with `AutomationManager`
///   so a single iOS BG wake services both subsystems.
/// - Local notifications go through `AutomationNotificationDelegate`'s
///   category + deep-link plumbing — reuse, not duplication.
@Observable
@MainActor
public final class NotificationManager {

    public static let shared: NotificationManager = NotificationManager()

    static let foregroundTimerInterval: TimeInterval = 60
    private let monitorsStorageKey = "SolarLens.notifications.monitors"

    /// Pre-scheduled "imminent threshold" notification id used by the
    /// battery-level monitor. Stable so it can be replaced / cancelled
    /// across ticks. Exposed `internal` so AutomationManager can wipe
    /// it on automation termination too (defence in depth).
    static let batteryThresholdImminentIdPrefix =
        "notification.batteryLevel.imminent."

    /// Public read-only view of the currently-active monitors. SwiftUI
    /// reads this through Observation; mutations happen via
    /// `enable`/`disable`/`update`.
    public var activeMonitors: [NotificationMonitor] = []

    @ObservationIgnored
    internal var energyManager: any EnergyManager = SolarManager.shared

    private var timer: Timer?

    private init() {
        restorePersistedState()
    }

    // MARK: - Public API

    /// Add a monitor and run its first tick immediately.
    public func enable(_ monitor: NotificationMonitor) {
        var newMonitor = monitor
        newMonitor.enabledAt = newMonitor.enabledAt == .distantPast
            ? Date() : newMonitor.enabledAt
        newMonitor.armState = .armed
        newMonitor.nextCheckAt = Date()  // tick immediately
        activeMonitors.append(newMonitor)
        persistState()
        log(
            info: "Notification enabled: \(monitor.kind.rawValue) \(describe(monitor))"
        )

        Task { await tick(monitorId: newMonitor.id) }
        ensureForegroundTimerStarted()
    }

    /// Replace an existing monitor's config. Keeps id and runtime state
    /// (`lastValue` etc.) but resets the arm state to `.armed` so an
    /// edit makes the new threshold take effect immediately.
    public func update(_ monitor: NotificationMonitor) {
        guard let idx = activeMonitors.firstIndex(
            where: { $0.id == monitor.id }
        ) else { return }
        var merged = monitor
        // Preserve runtime fields the caller didn't necessarily set.
        merged.enabledAt = activeMonitors[idx].enabledAt
        merged.fireCount = activeMonitors[idx].fireCount
        merged.lastCheckAt = activeMonitors[idx].lastCheckAt
        merged.lastValue = activeMonitors[idx].lastValue
        merged.lastBatteryChargeRate =
            activeMonitors[idx].lastBatteryChargeRate
        // Reset arm + forecast so the edit takes effect on the next tick.
        merged.armState = .armed
        merged.forecastedTargetAt = nil
        merged.nextCheckAt = Date()
        activeMonitors[idx] = merged
        persistState()
        log(
            info: "Notification updated: \(merged.kind.rawValue) \(describe(merged))"
        )

        Task { await tick(monitorId: merged.id) }
    }

    /// Remove a monitor. Also cancels its pre-scheduled imminent
    /// notification, if any.
    public func disable(id: UUID) {
        guard let idx = activeMonitors.firstIndex(where: { $0.id == id })
        else { return }
        let removed = activeMonitors.remove(at: idx)
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: [
                    Self.batteryThresholdImminentIdPrefix + removed.id.uuidString
                ]
            )
        persistState()
        log(info: "Notification disabled: \(removed.kind.rawValue)")
        if activeMonitors.isEmpty {
            stopTimer()
        }
    }

    public func isEnabled(_ kind: SolarLensNotification) -> Bool {
        activeMonitors.contains { $0.kind == kind }
    }

    public func monitor(for kind: SolarLensNotification) -> NotificationMonitor? {
        activeMonitors.first { $0.kind == kind }
    }

    public var hasActiveMonitors: Bool { !activeMonitors.isEmpty }

    // MARK: - BG / scene-phase glue

    /// Called from `Solar_Lens_iOSApp.handleScenePhaseChange` via the
    /// `AutomationManager` BG-task handler so both subsystems share one
    /// wake-up.
    public func handleScenePhaseChange(
        _ oldPhase: ScenePhase,
        _ newPhase: ScenePhase
    ) {
        switch newPhase {
        case .active:
            ensureForegroundTimerStarted()
            // Force a tick on overdue monitors when the user surfaces.
            // 30 s floor prevents thrash when toggling between apps.
            let now = Date()
            for m in activeMonitors {
                if let next = m.nextCheckAt, now.timeIntervalSince(next) >= -1
                {
                    Task { await tick(monitorId: m.id) }
                }
            }
        case .inactive:
            break
        case .background:
            stopTimer()
        @unknown default:
            break
        }
    }

    /// Called by `AutomationManager.handleBackgroundTask` so a single BG
    /// wake services both subsystems. Returns when all overdue monitors
    /// have ticked once.
    public func runOverdueMonitorsInBackground() async {
        let now = Date()
        let dueIds = activeMonitors.compactMap { m -> UUID? in
            guard let next = m.nextCheckAt else { return m.id }
            return next <= now ? m.id : nil
        }
        for id in dueIds {
            await tick(monitorId: id)
        }
    }

    /// Returns the earliest `nextCheckAt` across all active monitors,
    /// so `AutomationManager.scheduleNextBackgroundCall` can pick the
    /// minimum of (its automation's due time, this) as the BG hint.
    public var earliestNextCheck: Date? {
        activeMonitors.compactMap(\.nextCheckAt).min()
    }

    // MARK: - Run loop

    private func tick(monitorId: UUID) async {
        guard let idx = activeMonitors.firstIndex(where: { $0.id == monitorId })
        else { return }
        var monitor = activeMonitors[idx]

        let overview: OverviewData?
        do {
            overview = try await energyManager.fetchOverviewData(
                lastOverviewData: nil
            )
        } catch {
            log(
                error:
                    "Notification \(monitor.kind.rawValue): fetch failed (\(error.localizedDescription)) — retry next tick"
            )
            // Schedule next attempt regardless.
            monitor.nextCheckAt = Date().addingTimeInterval(
                Self.recheckInterval(for: monitor.kind)
            )
            updateMonitor(monitor)
            return
        }

        guard let value = Self.readValue(
            for: monitor.kind, from: overview
        ) else {
            // Required telemetry missing — wait and retry.
            monitor.lastCheckAt = Date()
            monitor.nextCheckAt = Date().addingTimeInterval(
                Self.recheckInterval(for: monitor.kind)
            )
            updateMonitor(monitor)
            return
        }

        monitor.lastValue = value
        monitor.lastCheckAt = Date()
        if monitor.kind == .BatteryLevel {
            monitor.lastBatteryChargeRate =
                overview?.currentBatteryChargeRate
        }

        switch monitor.armState {
        case .armed:
            if monitor.conditionMet(value: value) {
                fire(&monitor)
            }
        case .firedWaitingForReset:
            if monitor.conditionResetMet(value: value) {
                monitor.armState = .armed
                monitor.forecastedTargetAt = nil
                log(
                    info:
                        "Notification \(monitor.kind.rawValue): re-armed (\(formatValue(value, for: monitor.kind)) — clearly left threshold)"
                )
            }
        }

        // Battery-level monitor: refresh the forecast + imminent backstop.
        if monitor.kind == .BatteryLevel, monitor.armState == .armed,
           let overview = overview
        {
            updateBatteryForecastAndBackstop(
                monitor: &monitor, overview: overview
            )
        }

        monitor.nextCheckAt = Date().addingTimeInterval(
            Self.recheckInterval(for: monitor.kind)
        )
        updateMonitor(monitor)
    }

    /// Fires a single notification and transitions the monitor's arm
    /// state. For `.once` monitors that means terminate; for
    /// `.everyReoccurrence` monitors it means enter the
    /// `firedWaitingForReset` state and re-arm later.
    private func fire(_ monitor: inout NotificationMonitor) {
        monitor.lastFiredAt = Date()
        monitor.fireCount += 1
        postFiredNotification(monitor: monitor)
        NotificationHistoryManager.shared.record(
            NotificationFiredEvent(
                id: UUID(),
                kind: monitor.kind,
                value: monitor.lastValue ?? 0,
                threshold: monitor.threshold,
                comparison: monitor.comparison,
                time: monitor.lastFiredAt ?? Date()
            )
        )
        cancelBatteryImminentBackstop(monitor: monitor)
        log(
            info:
                "Notification \(monitor.kind.rawValue) fired (\(formatValue(monitor.lastValue ?? 0, for: monitor.kind)) — \(describe(monitor)))"
        )
        switch monitor.repeatMode {
        case .once:
            // Caller (`tick`) replaces this monitor in the array; we
            // remove it below after returning.
            monitor.armState = .firedWaitingForReset  // placeholder; ignored
            monitor.nextCheckAt = nil
        case .everyReoccurrence:
            monitor.armState = .firedWaitingForReset
        }
    }

    private func updateMonitor(_ monitor: NotificationMonitor) {
        // For single-fire monitors that just fired, remove them.
        if monitor.repeatMode == .once, monitor.lastFiredAt != nil,
           monitor.fireCount > 0
        {
            activeMonitors.removeAll { $0.id == monitor.id }
        } else if let idx = activeMonitors.firstIndex(
            where: { $0.id == monitor.id }
        ) {
            activeMonitors[idx] = monitor
        }
        persistState()
        if activeMonitors.isEmpty {
            stopTimer()
        }
    }

    // MARK: - Per-kind value readers

    /// Pull the canonical value for `kind` out of the overview. Returns
    /// `nil` when the metric is not available (e.g. no battery on the
    /// system → BatteryLevel is missing).
    static func readValue(
        for kind: SolarLensNotification, from overview: OverviewData?
    ) -> Int? {
        guard let overview else { return nil }
        switch kind {
        case .BatteryLevel:        return overview.currentBatteryLevel
        case .SolarProduction:     return overview.currentSolarProduction
        case .GridExport:          return overview.currentSolarToGrid
        case .GridImport:          return overview.currentGridToHouse
        case .OverallConsumption:  return overview.currentOverallConsumption
        case .ChargingThroughput:
            // Sum of currentPower across all charging stations, in W.
            // Returns 0 (a meaningful comparison) when no stations are
            // configured — the user just gets a notification telling
            // them "current 0 ≤ threshold" if they pick `equalOrBelow`
            // with no stations, which is technically correct.
            return overview.chargingStations
                .reduce(0) { $0 + $1.currentPower }
        }
    }

    /// Per-kind polling cadence. Battery and solar move slowly; grid /
    /// consumption / charging can jump in seconds, but we are bounded by
    /// the Solar Manager backend's own update interval (~15 s) plus iOS
    /// BG budget — five-minute cadence is the same proven sweet spot
    /// used by the legacy battery-level automation.
    static func recheckInterval(for kind: SolarLensNotification) -> TimeInterval {
        return 5 * 60
    }

    // MARK: - Battery-level forecast backstop

    /// Refresh the linear forecast for the battery-level monitor and,
    /// when the threshold is imminent (≤ 15 min away), pre-schedule a
    /// calendar-triggered notification at the predicted moment. Same
    /// mechanism the old automation used — see ADR-001.
    private func updateBatteryForecastAndBackstop(
        monitor: inout NotificationMonitor,
        overview: OverviewData
    ) {
        let seconds = overview.forecastSeconds(toReach: monitor.threshold)
        monitor.forecastedTargetAt = seconds.flatMap {
            $0 > 0 ? Date().addingTimeInterval($0) : nil
        }
        let imminentWindow: TimeInterval = 15 * 60
        guard let secondsToTarget = seconds,
              secondsToTarget > 0,
              secondsToTarget <= imminentWindow
        else {
            cancelBatteryImminentBackstop(monitor: monitor)
            return
        }
        let firesAt = Date().addingTimeInterval(secondsToTarget)
        scheduleBatteryImminentBackstop(monitor: monitor, at: firesAt)
        // Align the next tick to right after the forecast moment.
        monitor.nextCheckAt = min(
            monitor.nextCheckAt
                ?? Date().addingTimeInterval(Self.recheckInterval(for: .BatteryLevel)),
            firesAt.addingTimeInterval(30)
        )
    }

    private func scheduleBatteryImminentBackstop(
        monitor: NotificationMonitor, at date: Date
    ) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Battery level reached")
        let comparator: String
        switch monitor.comparison {
        case .equalOrAbove: comparator = "≥"
        case .equalOrBelow: comparator = "≤"
        }
        content.body = String(
            localized:
                "Your house battery is forecast to reach \(comparator) \(monitor.threshold)% — open Solar Lens to see the live state."
        )
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        content.categoryIdentifier =
            AutomationNotificationDelegate.openHomeCategoryId
        content.userInfo = [
            AutomationNotificationDelegate.deepLinkUserInfoKey:
                "solarlens://home",
        ]

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: date
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: comps, repeats: false
        )
        let id = Self.batteryThresholdImminentIdPrefix + monitor.id.uuidString
        let request = UNNotificationRequest(
            identifier: id, content: content, trigger: trigger
        )
        Task {
            center.removePendingNotificationRequests(withIdentifiers: [id])
            try? await center.add(request)
        }
    }

    private func cancelBatteryImminentBackstop(monitor: NotificationMonitor) {
        let id = Self.batteryThresholdImminentIdPrefix + monitor.id.uuidString
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [id])
    }

    // MARK: - Posting fired notifications

    private func postFiredNotification(monitor: NotificationMonitor) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        content.categoryIdentifier =
            AutomationNotificationDelegate.openHomeCategoryId
        content.userInfo = [
            AutomationNotificationDelegate.deepLinkUserInfoKey:
                "solarlens://notifications",
        ]

        content.title = String(localized: monitor.kind.localizedTitleKey)
        let comparator: String
        switch monitor.comparison {
        case .equalOrAbove: comparator = "≥"
        case .equalOrBelow: comparator = "≤"
        }
        let valueText = formatValue(
            monitor.lastValue ?? 0, for: monitor.kind
        )
        let thresholdText = formatValue(
            monitor.threshold, for: monitor.kind
        )
        switch monitor.kind {
        case .BatteryLevel:
            content.body = String(
                localized:
                    "Your house battery is at \(valueText) (target \(comparator) \(thresholdText))."
            )
        default:
            content.body = String(
                localized:
                    "Current \(valueText) (target \(comparator) \(thresholdText))."
            )
        }

        let req = UNNotificationRequest(
            identifier:
                "notification.\(monitor.kind.rawValue).\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        Task {
            _ = try? await center.requestAuthorization(
                options: [.alert, .sound]
            )
            try? await center.add(req)
        }
    }

    // MARK: - Persistence

    private func persistState() {
        let defaults = UserDefaults.standard
        if activeMonitors.isEmpty {
            defaults.removeObject(forKey: monitorsStorageKey)
            return
        }
        if let data = try? JSONEncoder().encode(activeMonitors) {
            defaults.set(data, forKey: monitorsStorageKey)
        }
    }

    private func restorePersistedState() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: monitorsStorageKey),
           let restored = try? JSONDecoder().decode(
            [NotificationMonitor].self, from: data
           )
        {
            activeMonitors = restored
        }
    }

    /// Replace the entire active-monitors list. Used only by the legacy
    /// `AutomationNotifyOnBatteryLevel` → notifications migration.
    /// Not part of the public API.
    func _replaceForMigration(_ monitors: [NotificationMonitor]) {
        activeMonitors = monitors
        persistState()
        if !monitors.isEmpty {
            ensureForegroundTimerStarted()
        }
    }

    // MARK: - Foreground timer

    private func ensureForegroundTimerStarted() {
        guard !activeMonitors.isEmpty else { return }
        if timer == nil {
            timer = Timer.scheduledTimer(
                withTimeInterval: Self.foregroundTimerInterval,
                repeats: true
            ) { [weak self] _ in
                guard let self else { return }
                let now = Date()
                let dueIds = self.activeMonitors.compactMap {
                    m -> UUID? in
                    guard let next = m.nextCheckAt else { return nil }
                    return next < now ? m.id : nil
                }
                for id in dueIds {
                    Task { @MainActor in await self.tick(monitorId: id) }
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Formatting helpers

    private func formatValue(
        _ value: Int, for kind: SolarLensNotification
    ) -> String {
        if kind.isPercent {
            return "\(value)%"
        }
        // Watts → kW with 1 decimal.
        let kw = Double(value) / 1000.0
        return String(format: "%.1f kW", kw)
    }

    private func describe(_ monitor: NotificationMonitor) -> String {
        let comparator: String
        switch monitor.comparison {
        case .equalOrAbove: comparator = "≥"
        case .equalOrBelow: comparator = "≤"
        }
        let repeatTag: String
        switch monitor.repeatMode {
        case .once: repeatTag = "once"
        case .everyReoccurrence: repeatTag = "repeat"
        }
        return "\(comparator) \(formatValue(monitor.threshold, for: monitor.kind)) [\(repeatTag)]"
    }

    // MARK: - Logging (piggybacks on AutomationLogManager)

    private func log(info message: String) {
        AutomationLogManager.shared.log(
            .init(
                time: Date(),
                message: LocalizedStringResource(stringLiteral: message),
                level: .Info
            )
        )
    }

    private func log(error message: String) {
        AutomationLogManager.shared.log(
            .init(
                time: Date(),
                message: LocalizedStringResource(stringLiteral: message),
                level: .Error
            )
        )
    }
}
