import BackgroundTasks
internal import Foundation
import SwiftUI
internal import UserNotifications

@Observable
@MainActor
public final class AutomationManager: AutomationHost {

    public static let shared: AutomationManager = AutomationManager()

    /// Posted whenever an automation terminates (graceful, cancelled, or
    /// failed). Listeners — currently `Solar_Lens_iOSApp` — use this to
    /// trigger a fresh fetch of `OverviewData` so the in-app charging
    /// mode reflects whatever the automation switched the charging station to.
    public static let automationTerminatedNotification = Notification.Name(
        "com.marcduerst.SolarManagerWatch.AutomationTerminated"
    )

    /// Optional `userInfo` keys posted on
    /// `automationTerminatedNotification` when the run also switched
    /// the charging station charging mode. The app uses these to prime an
    /// optimistic override on `CurrentBuildingState` so the UI reflects
    /// the new mode immediately, without waiting for the backend to
    /// propagate the change through `OverviewData`.
    public static let terminatedChargingStationIdKey =
        "com.marcduerst.SolarManagerWatch.terminatedChargingStationId"
    public static let terminatedChargingModeRawKey =
        "com.marcduerst.SolarManagerWatch.terminatedChargingModeRaw"

    private let identifier =
        "com.marcduerst.SolarManagerWatch.AutomationRunner"
    /// Second, complementary wake source (story #6). `BGProcessingTask`
    /// is granted more readily than `BGAppRefreshTask` while charging /
    /// on Wi-Fi (often overnight), so registering both gives notifications
    /// more chances to be checked on time. Both drain the same subsystems.
    private let processingIdentifier =
        "com.marcduerst.SolarManagerWatch.NotificationProcessing"
    static private let foregroundTimerInterval: TimeInterval = 60
    private let stateStorageKey = "SolarLens.activeAutomationState"
    private let parametersStorageKey = "SolarLens.activeAutomationParameters"

    public var activeAutomation: Automation? {
        activeState?.automation
    }

    public var activeStateSnapshot: AutomationState? { activeState }
    public var activeParametersSnapshot: AutomationParameters? {
        activeTaskParameters
    }

    @ObservationIgnored
    internal var energyManager: any EnergyManager = SolarManager.shared

    private var activeState: AutomationState? = nil
    private var activeTaskParameters: AutomationParameters? = nil
    private var activeAutomationName: LocalizedStringResource {
        activeState?.automation?.getAutomationTask()?.automationName ?? "-"
    }
    private var timer: Timer?
    /// Last time the foreground-restore force-tick fired. Used as a
    /// thrash floor in `handleScenePhaseChange(.active)` so flicking
    /// between apps doesn't re-fetch overview data each time.
    private var lastForegroundTickAt: Date?
    @ObservationIgnored
    private var lastBackgroundFireAt: Date?

    private init() {
        restorePersistedState()
    }

    public func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: identifier,
            using: nil
        ) { task in
            self.handleBackgroundTask(task: task as! BGAppRefreshTask)
        }

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: processingIdentifier,
            using: nil
        ) { task in
            self.handleProcessingTask(task: task as! BGProcessingTask)
        }

        logDebug(message: "Background tasks registered with iOS")
    }

    public func handleScenePhaseChange(
        _ oldPhase: ScenePhase,
        _ newPhase: ScenePhase
    ) {
        switch newPhase {
        case .active:
            if activeState?.automation != nil {
                logDebug(message: "App became active (foreground)")
                // Force a tick when the user surfaces the app, unless
                // we've already ticked very recently. Catches three
                // related cases:
                //
                //   - iOS didn't fire BGAppRefreshTask while we were
                //     suspended → `nextTaskRun` is overdue.
                //   - A pre-scheduled "threshold imminent" /
                //     "floor due" notification just fired in the
                //     background, the user opened the app to verify,
                //     and the LA/UI still shows the previous tick's
                //     pre-threshold data because we're not strictly
                //     "overdue" yet.
                //   - User opens the app between BG cycles just to
                //     check progress — fresh data is the natural
                //     expectation.
                //
                // The 30-second floor prevents repeated tick storms
                // when the user toggles between apps in quick
                // succession.
                let forceTick: Bool = {
                    if let last = lastForegroundTickAt,
                        Date().timeIntervalSince(last) < 30
                    {
                        return false
                    }
                    return true
                }()
                if forceTick {
                    lastForegroundTickAt = Date()
                    Task { await self.runActiveAutomation() }
                }
                // Safety net for the watch-start flow: if the Live
                // Activity wasn't created at start time (most often
                // because the initial Activity.request was rejected from
                // background context), the coordinator's lazy-start
                // inside `update()` will pick it up now that we're
                // foreground. Cheap no-op if the LA is already up.
                if let state = activeState,
                    let params = activeTaskParameters
                {
                    AutomationLiveActivityCoordinator.shared.update(
                        state: state, parameters: params
                    )
                }
            }
            ensureForegroundTimerStarted()
        case .inactive:
            break
        case .background:
            stopTimer()
            if activeState?.automation != nil
                || NotificationManager.shared.hasActiveMonitors
            {
                logDebug(
                    message: "App moved to background — scheduling BG refresh"
                )
                scheduleNextBackgroundCall()
            }
        @unknown default:
            break
        }
    }

    public func startAutomation(
        automation: Automation,
        parameters: AutomationParameters
    ) {
        if activeState != nil {
            logError(
                message:
                    "Cannot start \(automation.rawValue): another automation (\(activeAutomationName)) is already running"
            )
            return
        }

        let initialState = AutomationState(automation: automation)
        activeState = initialState
        activeTaskParameters = parameters
        persistState()

        if let p = parameters.batteryToCar {
            let fallback = String(
                localized: p.fallbackChargingMode.localizedTitle
            )
            logInfo(
                message:
                    "Automation \(activeAutomationName) started — floor \(p.minBatteryLevel)%, fallback after run: \(fallback)"
            )
        } else {
            logInfo(message: "Automation \(activeAutomationName) started")
        }

        AutomationLiveActivityCoordinator.shared.start(
            automation: automation,
            state: initialState,
            parameters: parameters
        )

        Task {
            await runActiveAutomation()
        }

        ensureForegroundTimerStarted()
    }

    public func cancelActiveAutomation() {
        guard let state = activeState,
              let params = activeTaskParameters else {
            // No active automation, but the caller is still asking us
            // to cancel something — most commonly the Stop button on
            // a Live Activity that's still showing the previous run's
            // post-stop linger (`dismissalPolicy: .after(.now + 120)`).
            // Without this defensive sweep the tap would silently
            // do nothing and the LA would sit there for the rest of
            // its dismissal window. Tear down any system LA of our
            // type immediately so the button actually does what the
            // user expects.
            Task {
                await AutomationLiveActivityCoordinator.shared
                    .dismissAllStaleActivities(
                        reason: "cancel tapped with no active automation"
                    )
            }
            return
        }
        guard let task = state.automation?.getAutomationTask() else {
            Task { await terminateAutomation(reason: .cancelled) }
            return
        }
        if let p = params.batteryToCar {
            let fallback = String(
                localized: p.fallbackChargingMode.localizedTitle
            )
            logInfo(
                message:
                    "Automation \(activeAutomationName) cancelled by user — switching charging station to \(fallback)"
            )
        } else if let p = params.autoResetChargingMode {
            let fallback = String(
                localized: p.afterResetChargingMode.localizedTitle
            )
            logInfo(
                message:
                    "Automation \(activeAutomationName) cancelled by user — switching charging station to \(fallback)"
            )
        } else {
            logInfo(
                message:
                    "Automation \(activeAutomationName) cancelled by user"
            )
        }

        Task {
            // Best-effort: switch charging station to the per-automation fallback
            // mode. Both currently-known automations end on a fallback;
            // future automations that don't touch the charging station can be
            // added without a branch here.
            if let p = params.batteryToCar {
                let fallbackName = String(
                    localized: p.fallbackChargingMode.localizedTitle
                )
                do {
                    _ = try await self.energyManager.setCarChargingMode(
                        sensorId: p.chargingDeviceId,
                        carCharging: ControlCarChargingRequest(
                            chargingMode: p.fallbackChargingMode
                        )
                    )
                } catch {
                    self.logError(
                        message:
                            "Cancel: failed to switch charging station to \(fallbackName) (\(error.localizedDescription)) — please verify the charging station state in the Solar Manager app"
                    )
                }
            } else if let p = params.autoResetChargingMode {
                let fallbackName = String(
                    localized: p.afterResetChargingMode.localizedTitle
                )
                do {
                    _ = try await self.energyManager.setCarChargingMode(
                        sensorId: p.chargingDeviceId,
                        carCharging: ControlCarChargingRequest(
                            chargingMode: p.afterResetChargingMode
                        )
                    )
                } catch {
                    self.logError(
                        message:
                            "Cancel: failed to switch charging station to \(fallbackName) (\(error.localizedDescription)) — please verify the charging station state in the Solar Manager app"
                    )
                }
            }
            // Mark stopReason and end.
            if var s = self.activeState?.batteryToCar {
                s.stopReason = .cancelled
                self.activeState = AutomationState(
                    automation: state.automation!,
                    status: .finishedSuccessful,
                    nextTaskRun: nil,
                    batteryToCar: s
                )
            } else if var s = self.activeState?.autoResetChargingMode {
                s.stopReason = .cancelled
                s.appliedAfterResetModeAt = Date()
                self.activeState = AutomationState(
                    automation: state.automation!,
                    status: .finishedSuccessful,
                    nextTaskRun: nil,
                    autoResetChargingMode: s
                )
            }
            await self.terminateAutomation(reason: .cancelled)
            _ = task // silence unused warning
        }
    }

    // MARK: - Logging

    func logSuccess() {
        AutomationLogManager.shared.log(
            .init(
                message:
                    "Successfully ran automation \(activeAutomationName).",
                level: .Success
            )
        )
    }

    func logInfo(message: LocalizedStringResource) {
        AutomationLogManager.shared.log(
            .init(time: Date(), message: message, level: .Info)
        )
    }

    func logError(message: LocalizedStringResource) {
        AutomationLogManager.shared.log(
            .init(time: Date(), message: message, level: .Error)
        )
    }

    func logDebug(message: LocalizedStringResource) {
        AutomationLogManager.shared.log(
            .init(time: Date(), message: message, level: .Debug)
        )
    }

    func logFailure() {
        AutomationLogManager.shared.log(
            .init(
                message: "Automation \(activeAutomationName) failed!",
                level: .Failure
            )
        )
    }

    // MARK: - Background

    private func handleBackgroundTask(task: BGAppRefreshTask) {
        let start = Date()
        let gap = lastBackgroundFireAt.map {
            Int(start.timeIntervalSince($0) / 60)
        }
        if let gap {
            logInfo(
                message: "iOS gave us BG runtime (gap: \(gap) min)"
            )
        } else {
            logInfo(message: "iOS gave us BG runtime")
        }
        lastBackgroundFireAt = start

        let hasAutomation = activeState?.automation?.getAutomationTask() != nil
        let hasNotifications = NotificationManager.shared.hasActiveMonitors
        guard hasAutomation || hasNotifications else {
            logDebug(message: "BG fired but nothing to drain — skipping")
            task.setTaskCompleted(success: true)
            return
        }

        task.expirationHandler = {
            let durationSec = Int(Date().timeIntervalSince(start))
            self.logError(
                message:
                    "BG runtime expired by iOS after \(durationSec)s"
            )
            task.setTaskCompleted(success: false)
            self.scheduleNextBackgroundCall()
        }

        Task {
            if hasAutomation {
                await runActiveAutomation()
            }
            // Drain notifications on the same wake-up — single BG budget
            // serves both subsystems. See ADR-002.
            if hasNotifications {
                await NotificationManager.shared
                    .runOverdueMonitorsInBackground()
            }
            let durationSec = Int(Date().timeIntervalSince(start))
            self.logDebug(
                message: "BG tick completed in \(durationSec)s"
            )
            task.setTaskCompleted(success: true)

            if activeState?.automation != nil
                || NotificationManager.shared.hasActiveMonitors
            {
                scheduleNextBackgroundCall()
            }
        }
    }

    /// Second wake source — same drain as `handleBackgroundTask`, but
    /// triggered by the more-readily-granted `BGProcessingTask` (story #6).
    private func handleProcessingTask(task: BGProcessingTask) {
        let start = Date()
        logInfo(message: "iOS gave us BG processing runtime")
        lastBackgroundFireAt = start

        let hasAutomation = activeState?.automation?.getAutomationTask() != nil
        let hasNotifications = NotificationManager.shared.hasActiveMonitors
        guard hasAutomation || hasNotifications else {
            logDebug(message: "BG processing fired but nothing to drain")
            task.setTaskCompleted(success: true)
            return
        }

        task.expirationHandler = {
            self.logError(message: "BG processing runtime expired by iOS")
            task.setTaskCompleted(success: false)
            self.scheduleNextProcessingCall()
        }

        Task {
            if hasAutomation { await runActiveAutomation() }
            if hasNotifications {
                await NotificationManager.shared
                    .runOverdueMonitorsInBackground()
            }
            task.setTaskCompleted(success: true)
            if activeState?.automation != nil
                || NotificationManager.shared.hasActiveMonitors
            {
                scheduleNextProcessingCall()
            }
        }
    }

    private func scheduleNextProcessingCall() {
        let request = BGProcessingTaskRequest(identifier: processingIdentifier)
        // We need network to poll Solar Manager; do not require external
        // power so daytime PV events (e.g. battery reaching 100 %) can
        // still be serviced, while iOS remains free to prefer charging.
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false

        let minimum = Date(timeIntervalSinceNow: 60)
        let automationNext = activeState?.nextTaskRun
        let notificationsNext =
            NotificationManager.shared.earliestNextCheck
        let candidates = [automationNext, notificationsNext].compactMap { $0 }
        let next = candidates.min() ?? minimum
        request.earliestBeginDate = max(next, minimum)

        do {
            try BGTaskScheduler.shared.submit(request)
            logDebug(
                message:
                    "Next background processing scheduled for \(format(date: request.earliestBeginDate))"
            )
        } catch {
            logDebug(
                message:
                    "Skipping BG processing schedule: \(error.localizedDescription)"
            )
        }
    }

    private func scheduleNextBackgroundCall() {
        scheduleNextProcessingCall()
        let request = BGAppRefreshTaskRequest(identifier: identifier)

        // Hint iOS with the best-known due date — the minimum across
        // the active automation's nextTaskRun and the earliest pending
        // notification check. The two managers share this BG task
        // identifier (ADR-002) so both contribute to the hint.
        let minimum = Date(timeIntervalSinceNow: 60)
        let automationNext = activeState?.nextTaskRun
        let notificationsNext =
            NotificationManager.shared.earliestNextCheck
        let candidates = [automationNext, notificationsNext].compactMap { $0 }
        let next = candidates.min() ?? minimum
        request.earliestBeginDate = max(next, minimum)

        do {
            try BGTaskScheduler.shared.submit(request)
            logDebug(
                message:
                    "Next background check scheduled for \(format(date: request.earliestBeginDate))"
            )
        } catch {
            // BGTaskScheduler returns "unavailable" (error 1) on the
            // simulator and on real devices that haven't been used long
            // enough yet — neither is a real failure. Demote to debug so
            // the user-facing automation log doesn't look alarming.
            logDebug(
                message:
                    "Skipping BG refresh schedule: \(error.localizedDescription)"
            )
        }
    }

    private func format(date: Date?) -> String {
        guard let date else { return "—" }
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f.string(from: date)
    }

    // MARK: - Run loop

    private func runActiveAutomation() async {
        guard let activeTask = activeState?.automation?.getAutomationTask(),
              let currentState = activeState,
              let activeTaskParameters else {
            return
        }

        let maxRetries = 3
        var currentRetry = 0

        while currentRetry <= maxRetries {
            do {
                let newState = try await activeTask.run(
                    host: self,
                    parameters: activeTaskParameters,
                    state: currentState
                )

                activeState = newState
                persistState()

                AutomationLiveActivityCoordinator.shared.update(
                    state: newState,
                    parameters: activeTaskParameters
                )

                if newState.status == .finishedSuccessful {
                    await terminateAutomation(reason: mapStopReason(newState))
                } else if newState.status == .failed {
                    await terminateAutomation(reason: .failed)
                }
                return
            } catch {
                currentRetry += 1
                logDebug(
                    message:
                        "Automation tick failed (attempt \(currentRetry)/\(maxRetries))"
                )
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }

        logError(message: "Automation tick: all retries exhausted")
        await terminateAutomation(reason: .failed)
    }

    // MARK: - Termination

    enum TerminationReason {
        case softFloorReached
        case capped
        case cancelled
        case resetCompleted
        case conditionMet
        case timedOut
        case carNotCharging
        case userOverride
        case failed
    }

    /// Map the per-automation stop reason recorded on the state to the
    /// generic `TerminationReason` that drives notifications and
    /// telemetry. Each automation contributes its own reason space; the
    /// switch here grows by one branch per new automation.
    private func mapStopReason(
        _ state: AutomationState
    ) -> TerminationReason {
        if let reason = state.batteryToCar?.stopReason {
            switch reason {
            case .softFloorReached: return .softFloorReached
            case .capped:           return .capped
            case .cancelled:        return .cancelled
            case .carNotCharging:   return .carNotCharging
            case .userOverride:     return .userOverride
            }
        }
        if let reason = state.autoResetChargingMode?.stopReason {
            switch reason {
            case .resetCompleted:   return .resetCompleted
            case .cancelled:        return .cancelled
            case .userOverride:     return .userOverride
            }
        }
        return .failed
    }

    /// Async because the Live Activity end() needs to be awaited
    /// before iOS suspends the process — otherwise BG ticks and
    /// scenePhase observers can race the BGTask completion / suspend
    /// and leave the LA stuck on the Lock Screen indefinitely.
    private func terminateAutomation(
        reason: TerminationReason
    ) async {
        let snapshot = activeState
        let snapshotParams = activeTaskParameters

        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier)
        stopTimer()

        // Cancel any per-automation pending pre-scheduled notifications
        // so a stale heads-up pop-up doesn't fire after the user
        // already cancelled or the run already finished.
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: [
                    AutomationAutoResetChargingMode
                        .resetDueNotificationId,
                    AutomationBatteryToCar
                        .softFloorDueNotificationId,
                ]
            )

        if let snapshot, let snapshotParams {
            await AutomationLiveActivityCoordinator.shared.end(
                state: snapshot,
                parameters: snapshotParams
            )
        }

        postFinishedNotification(
            reason: reason,
            state: snapshot,
            params: snapshotParams
        )

        activeState = nil
        activeTaskParameters = nil
        persistState()

        // Tell whoever's interested that an automation just ended so the
        // app can refetch overview data — the charging station mode visible in the
        // in-app UI is otherwise still the pre-termination value.
        //
        // When the run switched a charging station mode (Battery → Car cancel /
        // Auto-reset finish or cancel), include the station id + new
        // mode so the app can apply an optimistic UI override
        // immediately. The backend can take 30–60 s to propagate the
        // charging station change into the next OverviewData fetch, and without
        // an override the UI keeps showing the pre-termination mode for
        // that entire window.
        var userInfo: [AnyHashable: Any] = [:]
        if let p = snapshotParams?.batteryToCar {
            userInfo[Self.terminatedChargingStationIdKey] =
                p.chargingDeviceId
            userInfo[Self.terminatedChargingModeRawKey] =
                p.fallbackChargingMode.rawValue
        } else if let p = snapshotParams?.autoResetChargingMode {
            userInfo[Self.terminatedChargingStationIdKey] =
                p.chargingDeviceId
            userInfo[Self.terminatedChargingModeRawKey] =
                p.afterResetChargingMode.rawValue
        }
        NotificationCenter.default.post(
            name: Self.automationTerminatedNotification,
            object: nil,
            userInfo: userInfo
        )
    }

    // MARK: - Persistence

    private func persistState() {
        let defaults = UserDefaults.standard
        if let activeState {
            if let data = try? JSONEncoder().encode(activeState) {
                defaults.set(data, forKey: stateStorageKey)
            }
        } else {
            defaults.removeObject(forKey: stateStorageKey)
        }
        if let activeTaskParameters {
            if let data = try? JSONEncoder().encode(activeTaskParameters) {
                defaults.set(data, forKey: parametersStorageKey)
            }
        } else {
            defaults.removeObject(forKey: parametersStorageKey)
        }
    }

    private func restorePersistedState() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: stateStorageKey),
           let state = try? JSONDecoder().decode(
            AutomationState.self, from: data
           ) {
            activeState = state
        }
        if let data = defaults.data(forKey: parametersStorageKey),
           let params = try? JSONDecoder().decode(
            AutomationParameters.self, from: data
           ) {
            activeTaskParameters = params
        }
    }

    // MARK: - Notifications

    private func postFinishedNotification(
        reason: TerminationReason,
        state: AutomationState?,
        params: AutomationParameters?
    ) {
        let content = UNMutableNotificationContent()
        content.sound = .default
        var notificationKey: String = "automation"

        if let s = state?.batteryToCar, let p = params?.batteryToCar {
            notificationKey = "automation.batteryToCar"
            populateBatteryToCar(content: content, reason: reason, state: s, params: p)
        } else if let s = state?.autoResetChargingMode,
                  let p = params?.autoResetChargingMode {
            notificationKey = "automation.autoResetChargingMode"
            populateAutoResetChargingMode(
                content: content, reason: reason, state: s, params: p
            )
        } else {
            return
        }

        let req = UNNotificationRequest(
            identifier: "\(notificationKey).\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        let center = UNUserNotificationCenter.current()
        Task {
            _ = try? await center.requestAuthorization(
                options: [.alert, .sound]
            )
            try? await center.add(req)
        }
    }

    private func populateBatteryToCar(
        content: UNMutableNotificationContent,
        reason: TerminationReason,
        state s: AutomationBatteryToCarState,
        params p: AutomationBatteryToCarParameters
    ) {
        let kwh = String(format: "%.1f", s.kWhTransferred)
        let endSoc = s.endSoc ?? s.lastBatteryPercentage ?? 0
        let modeName = String(
            localized: p.fallbackChargingMode.localizedTitle
        )

        switch reason {
        case .softFloorReached:
            content.title = String(localized: "Battery-to-Car finished")
            content.body = String(
                localized:
                    "≈ \(kwh) kWh transferred from battery (\(s.startSoc)% → \(endSoc)%). Charging station switched to \(modeName)."
            )
        case .capped:
            content.title = String(localized: "Battery-to-Car stopped")
            content.body = String(
                localized:
                    "Stopped to avoid grid import. ≈ \(kwh) kWh transferred (\(s.startSoc)% → \(endSoc)%). Charging station switched to \(modeName)."
            )
        case .cancelled:
            content.title = String(localized: "Battery-to-Car cancelled")
            content.body = String(
                localized:
                    "Cancelled by you. ≈ \(kwh) kWh transferred so far. Charging station switched to \(modeName)."
            )
        case .carNotCharging:
            content.title = String(localized: "Battery-to-Car cancelled")
            content.body = String(
                localized:
                    "The car appears to be full or not connected — the charging station hasn't drawn any power. Switched to \(modeName)."
            )
        case .userOverride:
            content.title = String(localized: "Battery-to-Car cancelled")
            content.body = String(
                localized:
                    "You changed the charging mode manually. The automation stopped and left the charging station as you set it."
            )
        case .resetCompleted, .conditionMet, .timedOut:
            // Not applicable to Battery → Car, but compiler requires
            // exhaustiveness.
            content.title = String(localized: "Battery-to-Car finished")
            content.body = String(
                localized:
                    "≈ \(kwh) kWh transferred from battery (\(s.startSoc)% → \(endSoc)%). Charging station switched to \(modeName)."
            )
        case .failed:
            content.title = String(localized: "Battery-to-Car stopped")
            content.body = String(
                localized:
                    "An error occurred while monitoring. Charging station should now be on \(modeName)."
            )
        }
    }

    private func populateAutoResetChargingMode(
        content: UNMutableNotificationContent,
        reason: TerminationReason,
        state s: AutomationAutoResetChargingModeState,
        params p: AutomationAutoResetChargingModeParameters
    ) {
        let modeName = String(
            localized: p.afterResetChargingMode.localizedTitle
        )

        switch reason {
        case .resetCompleted:
            content.title = String(
                localized: "Auto-reset Charging Mode finished"
            )
            content.body = String(
                localized:
                    "Charging mode reset to \(modeName)."
            )
        case .cancelled:
            content.title = String(
                localized: "Auto-reset Charging Mode cancelled"
            )
            content.body = String(
                localized:
                    "Cancelled by you. Charging station switched to \(modeName)."
            )
        case .failed:
            content.title = String(
                localized: "Auto-reset Charging Mode stopped"
            )
            content.body = String(
                localized:
                    "Couldn't apply the charging-mode change. Please verify the charging station state in the Solar Manager app."
            )
        case .userOverride:
            content.title = String(
                localized: "Auto-reset Charging Mode cancelled"
            )
            content.body = String(
                localized:
                    "You changed the charging mode manually. The automation stopped and left the charging station as you set it."
            )
        case .softFloorReached, .capped, .conditionMet, .timedOut,
            .carNotCharging:
            // Not applicable to Auto-reset, but compiler requires
            // exhaustiveness. Use the generic "stopped" wording.
            content.title = String(
                localized: "Auto-reset Charging Mode stopped"
            )
            content.body = String(
                localized: "Charging station should now be on \(modeName)."
            )
        }
    }

    // MARK: - Timer

    private func ensureForegroundTimerStarted() {
        if timer == nil {
            timer = Timer.scheduledTimer(
                withTimeInterval: Self.foregroundTimerInterval,
                repeats: true
            ) { [weak self] _ in
                guard let self else { return }
                guard let nextRunAfter = self.activeState?.nextTaskRun else {
                    return
                }
                if nextRunAfter < Date() {
                    Task {
                        await self.runActiveAutomation()
                    }
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
