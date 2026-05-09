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
    /// mode reflects whatever the automation switched the wallbox to.
    public static let automationTerminatedNotification = Notification.Name(
        "com.marcduerst.SolarManagerWatch.AutomationTerminated"
    )

    private let identifier =
        "com.marcduerst.SolarManagerWatch.AutomationRunner"
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
                // If a tick is overdue (most likely because iOS didn't
                // fire BGAppRefreshTask in the meantime, or the user only
                // briefly foregrounds the app between checks), catch up
                // immediately instead of waiting up to 60 s for the next
                // foreground timer fire. Without this, a series of short
                // foreground sessions can leave the controller asleep
                // for many minutes — long enough for the wallbox to
                // drain past the soft floor.
                if let nextRun = activeState?.nextTaskRun, nextRun < Date() {
                    Task { await self.runActiveAutomation() }
                }
            }
            ensureForegroundTimerStarted()
        case .inactive:
            break
        case .background:
            stopTimer()
            if activeState?.automation != nil {
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
            return
        }
        guard let task = state.automation?.getAutomationTask() else {
            terminateAutomation(reason: .cancelled)
            return
        }
        if let p = params.batteryToCar {
            let fallback = String(
                localized: p.fallbackChargingMode.localizedTitle
            )
            logInfo(
                message:
                    "Automation \(activeAutomationName) cancelled by user — switching wallbox to \(fallback)"
            )
        } else if let p = params.autoResetChargingMode {
            let fallback = String(
                localized: p.afterResetChargingMode.localizedTitle
            )
            logInfo(
                message:
                    "Automation \(activeAutomationName) cancelled by user — switching wallbox to \(fallback)"
            )
        } else if params.notifyOnBatteryLevel != nil {
            // Monitoring-only — no wallbox to switch back, just stop.
            logInfo(
                message:
                    "Automation \(activeAutomationName) cancelled by user"
            )
        } else {
            logInfo(
                message:
                    "Automation \(activeAutomationName) cancelled by user"
            )
        }

        Task {
            // Best-effort: switch wallbox to the per-automation fallback
            // mode. Both currently-known automations end on a fallback;
            // future automations that don't touch the wallbox can be
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
                            "Cancel: failed to switch wallbox to \(fallbackName) (\(error.localizedDescription)) — please verify the wallbox state in the Solar Manager app"
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
                            "Cancel: failed to switch wallbox to \(fallbackName) (\(error.localizedDescription)) — please verify the wallbox state in the Solar Manager app"
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
            } else if var s = self.activeState?.notifyOnBatteryLevel {
                s.stopReason = .cancelled
                self.activeState = AutomationState(
                    automation: state.automation!,
                    status: .finishedSuccessful,
                    nextTaskRun: nil,
                    notifyOnBatteryLevel: s
                )
            }
            self.terminateAutomation(reason: .cancelled)
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

        guard activeState?.automation?.getAutomationTask() != nil else {
            logDebug(message: "BG fired but no automation active — skipping")
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
            await runActiveAutomation()
            let durationSec = Int(Date().timeIntervalSince(start))
            self.logDebug(
                message: "BG tick completed in \(durationSec)s"
            )
            task.setTaskCompleted(success: true)

            if activeState?.automation != nil {
                scheduleNextBackgroundCall()
            }
        }
    }

    private func scheduleNextBackgroundCall() {
        let request = BGAppRefreshTaskRequest(identifier: identifier)

        // Hint iOS with the best-known due date. Battery → Car keeps
        // nextTaskRun at "now + 60 s" so this collapses to the previous
        // behaviour. Auto-reset Charging Mode parks nextTaskRun at the
        // user-chosen reset date hours away — telling iOS that lets it
        // budget BG runtime for around that moment instead of waking us
        // every 15–60 min for nothing.
        let minimum = Date(timeIntervalSinceNow: 60)
        let next = activeState?.nextTaskRun ?? minimum
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
                    terminateAutomation(reason: mapStopReason(newState))
                } else if newState.status == .failed {
                    terminateAutomation(reason: .failed)
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
        terminateAutomation(reason: .failed)
    }

    // MARK: - Termination

    enum TerminationReason {
        case softFloorReached
        case capped
        case cancelled
        case resetCompleted
        case conditionMet
        case timedOut
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
            }
        }
        if let reason = state.autoResetChargingMode?.stopReason {
            switch reason {
            case .resetCompleted:   return .resetCompleted
            case .cancelled:        return .cancelled
            }
        }
        if let reason = state.notifyOnBatteryLevel?.stopReason {
            switch reason {
            case .conditionMet:     return .conditionMet
            case .timedOut:         return .timedOut
            case .cancelled:        return .cancelled
            }
        }
        return .failed
    }

    private func terminateAutomation(reason: TerminationReason) {
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
                    AutomationNotifyOnBatteryLevel
                        .thresholdDueNotificationId,
                ]
            )

        if let snapshot, let snapshotParams {
            AutomationLiveActivityCoordinator.shared.end(
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
        // app can refetch overview data — the wallbox mode visible in the
        // in-app UI is otherwise still the pre-termination value.
        NotificationCenter.default.post(
            name: Self.automationTerminatedNotification,
            object: nil
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
        } else if let s = state?.notifyOnBatteryLevel,
                  let p = params?.notifyOnBatteryLevel {
            notificationKey = "automation.notifyOnBatteryLevel"
            populateNotifyOnBatteryLevel(
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
                    "≈ \(kwh) kWh transferred from battery (\(s.startSoc)% → \(endSoc)%). Wallbox switched to \(modeName)."
            )
        case .capped:
            content.title = String(localized: "Battery-to-Car stopped")
            content.body = String(
                localized:
                    "Stopped to avoid grid import. ≈ \(kwh) kWh transferred (\(s.startSoc)% → \(endSoc)%). Wallbox switched to \(modeName)."
            )
        case .cancelled:
            content.title = String(localized: "Battery-to-Car cancelled")
            content.body = String(
                localized:
                    "Cancelled by you. ≈ \(kwh) kWh transferred so far. Wallbox switched to \(modeName)."
            )
        case .resetCompleted, .conditionMet, .timedOut:
            // Not applicable to Battery → Car, but compiler requires
            // exhaustiveness.
            content.title = String(localized: "Battery-to-Car finished")
            content.body = String(
                localized:
                    "≈ \(kwh) kWh transferred from battery (\(s.startSoc)% → \(endSoc)%). Wallbox switched to \(modeName)."
            )
        case .failed:
            content.title = String(localized: "Battery-to-Car stopped")
            content.body = String(
                localized:
                    "An error occurred while monitoring. Wallbox should now be on \(modeName)."
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
                    "Cancelled by you. Wallbox switched to \(modeName)."
            )
        case .failed:
            content.title = String(
                localized: "Auto-reset Charging Mode stopped"
            )
            content.body = String(
                localized:
                    "Couldn't apply the charging-mode change. Please verify the wallbox state in the Solar Manager app."
            )
        case .softFloorReached, .capped, .conditionMet, .timedOut:
            // Not applicable to Auto-reset, but compiler requires
            // exhaustiveness. Use the generic "stopped" wording.
            content.title = String(
                localized: "Auto-reset Charging Mode stopped"
            )
            content.body = String(
                localized: "Wallbox should now be on \(modeName)."
            )
        }
    }

    private func populateNotifyOnBatteryLevel(
        content: UNMutableNotificationContent,
        reason: TerminationReason,
        state s: AutomationNotifyOnBatteryLevelState,
        params p: AutomationNotifyOnBatteryLevelParameters
    ) {
        let level = s.lastBatteryLevel ?? 0
        let comparator: String
        switch p.comparison {
        case .equalOrAbove: comparator = "≥"
        case .equalOrBelow: comparator = "≤"
        }

        // The action button + tap-to-open routing both go through this
        // category. The userInfo carries a deep link that the
        // delegate's didReceive routes to the Now tab so the user lands
        // on the main screen.
        content.categoryIdentifier =
            AutomationNotificationDelegate.openHomeCategoryId
        content.userInfo = [
            AutomationNotificationDelegate.deepLinkUserInfoKey:
                "solarlens://home",
        ]
        content.interruptionLevel = .timeSensitive

        switch reason {
        case .conditionMet:
            content.title = String(
                localized: "Battery level reached"
            )
            content.body = String(
                localized:
                    "Your house battery is at \(level)% (target \(comparator) \(p.targetBatteryLevel)%)."
            )
        case .timedOut:
            content.title = String(
                localized: "Notify on battery level cancelled"
            )
            content.body = String(
                localized:
                    "24 hours passed and the battery never reached \(comparator) \(p.targetBatteryLevel)%. Last seen: \(level)%."
            )
        case .cancelled:
            content.title = String(
                localized: "Notify on battery level cancelled"
            )
            content.body = String(
                localized: "Cancelled by you."
            )
        case .failed:
            content.title = String(
                localized: "Notify on battery level stopped"
            )
            content.body = String(
                localized: "An error occurred while monitoring."
            )
        case .softFloorReached, .capped, .resetCompleted:
            // Not applicable to this automation, but compiler requires
            // exhaustiveness.
            content.title = String(
                localized: "Notify on battery level stopped"
            )
            content.body = String(
                localized: "Last seen: \(level)%."
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
