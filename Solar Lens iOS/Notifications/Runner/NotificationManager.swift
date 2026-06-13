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

    /// How far ahead a forecast crossing may be and still get a
    /// pre-scheduled backstop notification. Staggered per kind (story #6
    /// follow-up): the battery's charge/discharge trajectory is the most
    /// stable and most-complained-about, so it is planned far ahead (6 h)
    /// — the device is most likely idle for hours precisely on those long
    /// sunny-day charge cycles, and a crossing predicted 3–5 h out used to
    /// get no backstop at all under the old 90 min cap. Solar is left
    /// conservative (90 min) because cloud-driven swings make longer
    /// horizons unreliable.
    static func forecastWindow(for kind: SolarLensNotification) -> TimeInterval
    {
        switch kind {
        case .BatteryLevel: return 6 * 60 * 60
        default: return 90 * 60
        }
    }

    /// Pre-scheduled "threshold forecast" notification id prefix. Stable
    /// per monitor so it can be replaced / cancelled across ticks.
    /// Exposed `internal` so AutomationManager can wipe it too.
    static let thresholdForecastIdPrefix = "notification.forecast."

    /// Legacy id prefix from the battery-only backstop (pre story #6).
    /// Kept only so a pending notification scheduled by an older build is
    /// cancelled cleanly on disable/upgrade.
    static let batteryThresholdImminentIdPrefix =
        "notification.batteryLevel.imminent."

    /// Kinds whose crossing time can be linearly forecast from live
    /// telemetry, so we can pre-schedule a local notification that fires
    /// on time even while suspended. The other kinds (grid / consumption
    /// / charging) jump in seconds and are not forecastable — they rely
    /// on actually getting a BG tick.
    static func isForecastable(_ kind: SolarLensNotification) -> Bool {
        switch kind {
        case .BatteryLevel, .SolarProduction: return true
        default: return false
        }
    }

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
                    Self.thresholdForecastIdPrefix + removed.id.uuidString,
                    Self.batteryThresholdImminentIdPrefix + removed.id.uuidString,
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
            // On surfacing: tick overdue monitors, and also refresh every
            // forecastable armed monitor's backstop with fresh data.
            let now = Date()
            for m in activeMonitors {
                let due =
                    m.nextCheckAt.map { now.timeIntervalSince($0) >= -1 }
                    ?? true
                let forecastRefresh =
                    m.armState == .armed && Self.isForecastable(m.kind)
                if due || forecastRefresh {
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
        // Tick a monitor when it is due OR when it is a forecastable
        // armed monitor — the latter so every rare BG wake refreshes its
        // forecast backstop with fresh data, not just the monitor that
        // happened to be due (story #6).
        let ids = activeMonitors.compactMap { m -> UUID? in
            let due = m.nextCheckAt.map { $0 <= now } ?? true
            let forecastRefresh =
                m.armState == .armed && Self.isForecastable(m.kind)
            return (due || forecastRefresh) ? m.id : nil
        }
        for id in ids {
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

        // Keep the prior sample so non-rate kinds (solar) can estimate a
        // slope for the forecast backstop.
        monitor.previousValue = monitor.lastValue
        monitor.previousCheckAt = monitor.lastCheckAt
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

        // Default next tick; a forecast may tighten it below.
        monitor.nextCheckAt = Date().addingTimeInterval(
            Self.recheckInterval(for: monitor.kind)
        )

        // Forecastable kinds (battery, solar): refresh the forecast and
        // (re-)schedule the pre-scheduled backstop notification so it
        // fires on time even if iOS never grants another BG tick. May
        // pull `nextCheckAt` earlier to align with the predicted moment.
        if Self.isForecastable(monitor.kind), monitor.armState == .armed,
           let overview = overview
        {
            updateForecastAndBackstop(monitor: &monitor, overview: overview)
        }

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
        cancelForecastBackstop(monitor: monitor)
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

    // MARK: - Forecast backstop (battery + solar)

    /// Refresh the linear forecast for a forecastable monitor and, when
    /// the crossing is predicted within `forecastWindow`, pre-schedule a
    /// calendar-triggered notification at the predicted moment. This is
    /// the only mechanism that fires on time while the app is suspended
    /// (see story #6 / ADR-001). Re-armed on every tick, so a later tick
    /// with a corrected rate moves the notification to the better time.
    private func updateForecastAndBackstop(
        monitor: inout NotificationMonitor,
        overview: OverviewData
    ) {
        let seconds = forecastSecondsToThreshold(
            monitor: monitor, overview: overview
        )
        monitor.forecastedTargetAt = seconds.flatMap {
            $0 > 0 ? Date().addingTimeInterval($0) : nil
        }
        guard let secondsToTarget = seconds,
              secondsToTarget > 0,
              secondsToTarget <= Self.forecastWindow(for: monitor.kind)
        else {
            // No usable fresh forecast this tick. Crucially, do NOT delete
            // a backstop we already scheduled just because this single
            // sample was inconclusive (momentary idle rate, a passing
            // cloud, or a crossing still beyond the window): a transient
            // sample used to wipe a perfectly good pre-scheduled
            // notification, and if iOS then never granted another tick the
            // alert only fired hours later when the user picked the phone
            // up. Keep the last good backstop and only cancel when the
            // value is *clearly* moving away from the threshold, so the
            // predicted crossing genuinely won't happen (story #6 fix).
            if isHeadingAwayFromThreshold(monitor: monitor, overview: overview)
            {
                cancelForecastBackstop(monitor: monitor)
            }
            return
        }
        let firesAt = Date().addingTimeInterval(secondsToTarget)
        scheduleForecastBackstop(monitor: monitor, at: firesAt)
        // Align the next tick to right after the forecast moment so a
        // foreground/BG tick (if granted) can confirm with live data.
        monitor.nextCheckAt = min(
            monitor.nextCheckAt
                ?? Date().addingTimeInterval(
                    Self.recheckInterval(for: monitor.kind)
                ),
            firesAt.addingTimeInterval(30)
        )
    }

    /// Seconds until the threshold is forecast to be crossed, or `nil`
    /// when not forecastable / not heading toward the threshold.
    ///
    /// - `BatteryLevel`: charge-rate extrapolation (`forecastSeconds`).
    /// - `SolarProduction`: slope from the last two samples, guarded so
    ///   noisy / cloudy periods don't mis-fire (must be moving toward the
    ///   threshold, above a noise floor).
    private func forecastSecondsToThreshold(
        monitor: NotificationMonitor, overview: OverviewData
    ) -> TimeInterval? {
        switch monitor.kind {
        case .BatteryLevel:
            return overview.forecastSeconds(toReach: monitor.threshold)
        case .SolarProduction:
            return slopeForecastSeconds(monitor: monitor)
        default:
            return nil
        }
    }

    /// Two-sample linear slope forecast in watts. Conservative on
    /// purpose: requires the value to be moving *toward* the threshold
    /// from the correct side and faster than a noise floor (~50 W/min),
    /// so a flat or jittery signal produces no backstop.
    private func slopeForecastSeconds(
        monitor: NotificationMonitor
    ) -> TimeInterval? {
        guard let cur = monitor.lastValue,
              let curAt = monitor.lastCheckAt,
              let prev = monitor.previousValue,
              let prevAt = monitor.previousCheckAt
        else { return nil }
        let dt = curAt.timeIntervalSince(prevAt)
        guard dt > 0 else { return nil }

        let slopePerSec = Double(cur - prev) / dt  // W/s
        let noiseFloor = 50.0 / 60.0               // 50 W per minute

        switch monitor.comparison {
        case .equalOrAbove:
            // Must currently be below and rising.
            guard cur < monitor.threshold, slopePerSec > noiseFloor else {
                return nil
            }
        case .equalOrBelow:
            // Must currently be above and falling.
            guard cur > monitor.threshold, slopePerSec < -noiseFloor else {
                return nil
            }
        }

        let secs = Double(monitor.threshold - cur) / slopePerSec
        return secs > 0 ? secs : nil
    }

    /// Whether the live value is *clearly* moving away from the threshold,
    /// i.e. the predicted crossing this backstop was scheduled for will
    /// not happen on the current trend. Used to decide when it is safe to
    /// drop an already-scheduled backstop (a merely inconclusive tick must
    /// not — see `updateForecastAndBackstop`). Deliberately conservative:
    /// only a confident opposite trend, above the same noise floors the
    /// forecasts use, returns `true`.
    private func isHeadingAwayFromThreshold(
        monitor: NotificationMonitor, overview: OverviewData
    ) -> Bool {
        switch monitor.kind {
        case .BatteryLevel:
            // Use the signed charge rate (same ±50 W "idle" band the
            // battery forecast uses). When armed we are on the near side
            // of the threshold, so "away" = flowing in the wrong
            // direction.
            guard let rateW = overview.currentBatteryChargeRate else {
                return false
            }
            switch monitor.comparison {
            case .equalOrAbove: return rateW < -50  // discharging, target higher
            case .equalOrBelow: return rateW > 50   // charging, target lower
            }
        case .SolarProduction:
            guard let cur = monitor.lastValue,
                  let curAt = monitor.lastCheckAt,
                  let prev = monitor.previousValue,
                  let prevAt = monitor.previousCheckAt,
                  curAt.timeIntervalSince(prevAt) > 0
            else { return false }
            let slopePerSec =
                Double(cur - prev) / curAt.timeIntervalSince(prevAt)
            let noiseFloor = 50.0 / 60.0  // 50 W per minute
            switch monitor.comparison {
            case .equalOrAbove: return slopePerSec < -noiseFloor
            case .equalOrBelow: return slopePerSec > noiseFloor
            }
        default:
            return false
        }
    }

    private func scheduleForecastBackstop(
        monitor: NotificationMonitor, at date: Date
    ) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = String(localized: monitor.kind.localizedTitleKey)
        let comparator: String
        switch monitor.comparison {
        case .equalOrAbove: comparator = "≥"
        case .equalOrBelow: comparator = "≤"
        }
        let thresholdText = formatValue(
            monitor.threshold, for: monitor.kind
        )
        // Worded as a forecast/estimate, never a hard claim — the real
        // confirmation fires from an actual tick. Avoids a false
        // "reached X" when the rate changed (story #6 false-alarm note).
        content.body = String(
            localized:
                "Forecast to cross \(comparator) \(thresholdText) around now — open Solar Lens to verify."
        )
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        content.categoryIdentifier =
            AutomationNotificationDelegate.openHomeCategoryId
        content.userInfo = [
            AutomationNotificationDelegate.deepLinkUserInfoKey:
                "solarlens://notifications",
        ]

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: date
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: comps, repeats: false
        )
        let id = Self.thresholdForecastIdPrefix + monitor.id.uuidString
        let request = UNNotificationRequest(
            identifier: id, content: content, trigger: trigger
        )
        Task {
            center.removePendingNotificationRequests(withIdentifiers: [id])
            try? await center.add(request)
        }
    }

    private func cancelForecastBackstop(monitor: NotificationMonitor) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: [
                    Self.thresholdForecastIdPrefix + monitor.id.uuidString,
                    Self.batteryThresholdImminentIdPrefix
                        + monitor.id.uuidString,
                ]
            )
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
