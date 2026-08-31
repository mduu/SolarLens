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
    /// How long a successful wake registration is trusted before a foreground
    /// re-sync bothers the server again.
    static private let wakeResyncInterval: TimeInterval = 12 * 60 * 60
    // Shared with the Notification Service Extension (story #9 / ADR-006).
    private let stateStorageKey = AutomationSharedStore.activeStateKey
    private let parametersStorageKey =
        AutomationSharedStore.activeParametersKey

    public var activeAutomation: Automation? {
        activeState?.automation
    }

    /// True while an automation is running that actually has something to do
    /// between now and its end — i.e. one the server should nudge us about
    /// (story #9 slice 4). `AutoResetChargingMode` is excluded on purpose: it
    /// idles until its reset time, which the visible deadline push covers.
    public var needsSilentWakeWindow: Bool {
        activeState?.automation == .BatteryToCar
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
            // The Notification Service Extension may have executed a
            // scheduled automation while we were suspended (story #9).
            // Reconcile before anything else, so we don't tick a run that
            // already finished in the other process.
            Task { await self.adoptExternalCompletionIfNeeded() }

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

        // Ask the server to wake us at the end time (story #9). Best effort:
        // if this fails the run still finishes via BG tasks and the local
        // fallback notification, exactly as before.
        registerWakeSchedule(
            automation: automation,
            parameters: parameters,
            scheduleId: UUID().uuidString
        )
        WakeWindowCoordinator.shared.refresh()

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
        await adoptExternalCompletionIfNeeded()

        // Another process (the Notification Service Extension) may be
        // applying the same automation right now. Skip this tick rather than
        // issuing a second charging-mode call; the next tick picks it up.
        guard AutomationSharedStore.acquireTickLease() else {
            logDebug(
                message:
                    "Skipping tick — the notification extension is running this automation"
            )
            return
        }
        defer { AutomationSharedStore.releaseTickLease() }

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

    /// Drains both subsystems after a silent push woke the app (story #9).
    ///
    /// Same work as a background-task tick: run the active automation, check
    /// any due monitors, then re-arm the BG tasks. The push is an *extra* wake
    /// source, so it must leave the on-device schedule exactly as a BG wake
    /// would.
    public func handleRemoteWake() async {
        let hasAutomation = activeState?.automation?.getAutomationTask() != nil
        let hasNotifications = NotificationManager.shared.hasActiveMonitors
        guard hasAutomation || hasNotifications else {
            logDebug(message: "Push woke us but nothing to drain — skipping")
            return
        }

        logInfo(message: "Woken by a push notification")
        lastBackgroundFireAt = Date()

        if hasAutomation { await runActiveAutomation() }
        if hasNotifications {
            await NotificationManager.shared.runOverdueMonitorsInBackground()
        }

        if activeState?.automation != nil
            || NotificationManager.shared.hasActiveMonitors
        {
            scheduleNextBackgroundCall()
        }
        WakeWindowCoordinator.shared.refresh()
    }

    // MARK: - Server wake schedule (story #9)

    /// Registers the end time of a time-bound automation with the Solar Lens
    /// server, so a push can wake the Notification Service Extension at that
    /// moment even if the app has been force-quit.
    ///
    /// Only the timestamp and the notification's fallback text leave the
    /// device — the text is localized here, because the server does not know
    /// the user's language (ADR-006).
    /// - Parameter scheduleId: **one id per run**. Re-registering under the
    ///   same id updates that row; minting a new one on every call would leave
    ///   the previous row on the server and the device would be pushed once
    ///   per registration.
    private func registerWakeSchedule(
        automation: Automation,
        parameters: AutomationParameters,
        scheduleId: String
    ) {
        guard automation == .AutoResetChargingMode,
            let params = parameters.autoResetChargingMode
        else { return }

        let postName = String(
            localized: params.afterResetChargingMode.localizedTitle
        )
        let title = String(localized: "Auto-reset Charging Mode")
        let body = String(
            localized: "Reset time reached — applying \(postName)…"
        )

        Task {
            let result = await WakeScheduleClient.registerDeadline(
                scheduleId: scheduleId,
                automation: automation,
                fireAt: params.resetAt,
                title: title,
                body: body,
                deepLink: "solarlens://automations"
            )
            switch result {
            case .registered:
                self.logDebug(
                    message:
                        "Scheduled a server wake-up for the reset time"
                )
            case .skipped(let reason):
                self.logDebug(
                    message: "No server wake-up scheduled: \(reason)"
                )
            case .failed(let reason):
                self.logDebug(
                    message:
                        "Could not schedule the server wake-up (\(reason)) — falling back to background execution"
                )
            case .cancelled:
                break
            }
        }
    }

    /// Re-registers the active automation's wake-up. Called when the app comes
    /// to the foreground and when the APNs token changes, so a rotated token,
    /// a reinstall or a server-side data loss cannot leave a running
    /// automation without its push.
    ///
    /// Reuses the run's existing schedule id, so this updates the one row
    /// instead of adding another push per app launch — and skips the call
    /// entirely while a recent registration still stands, because this runs on
    /// every foreground and each call is a server execution we pay for.
    func resyncWakeSchedule(force: Bool = false) {
        guard let automation = activeState?.automation,
            let parameters = activeTaskParameters
        else { return }

        if !force, WakeScheduleClient.activeScheduleId != nil,
            let last = WakeScheduleClient.lastRegistrationAt,
            Date().timeIntervalSince(last) < Self.wakeResyncInterval
        {
            return
        }
        registerWakeSchedule(
            automation: automation,
            parameters: parameters,
            scheduleId: WakeScheduleClient.activeScheduleId
                ?? UUID().uuidString
        )
    }

    // MARK: - External completion (Notification Service Extension)

    /// Picks up a run that the Notification Service Extension executed while
    /// the app was suspended or force-quit (story #9 / ADR-006).
    ///
    /// The extension has already applied the charging mode, written the log
    /// entry and shown the user a notification with the real outcome. What is
    /// left for us is local teardown: end the Live Activity, drop the
    /// in-memory run, and tell the UI to refresh. Deliberately **no** second
    /// user notification.
    func adoptExternalCompletionIfNeeded() async {
        guard let outcome = AutomationSharedStore.externalOutcome else {
            return
        }
        AutomationSharedStore.externalOutcome = nil

        // Each variant is its own message rather than one with an
        // interpolated clause: a clause built in Swift would stay English in
        // every language.
        switch outcome.kind {
        case .applied:
            if let detail = outcome.detail {
                logInfo(
                    message:
                        "Automation finished in the background via push notification — charging station switched to \(detail)"
                )
            } else {
                logInfo(
                    message:
                        "Automation finished in the background via push notification"
                )
            }
        case .userOverride:
            logInfo(
                message:
                    "Automation stopped in the background via push notification — charging mode had been changed manually"
            )
        case .failed:
            if let detail = outcome.detail {
                logError(
                    message:
                        "Automation failed in the background via push notification: \(detail)"
                )
            } else {
                logError(
                    message:
                        "Automation failed in the background via push notification"
                )
            }
        }

        let snapshot = activeState
        let snapshotParams = activeTaskParameters

        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier)
        stopTimer()
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: [
                    AutomationAutoResetChargingMode.resetDueNotificationId,
                    AutomationBatteryToCar.softFloorDueNotificationId,
                ]
            )

        if let snapshot, let snapshotParams {
            await AutomationLiveActivityCoordinator.shared.end(
                state: snapshot,
                parameters: snapshotParams
            )
        } else {
            await AutomationLiveActivityCoordinator.shared
                .dismissAllStaleActivities(
                    reason: "automation completed by notification extension"
                )
        }

        activeState = nil
        activeTaskParameters = nil
        persistState()
        WakeScheduleClient.activeScheduleId = nil
        WakeWindowCoordinator.shared.refresh()

        var userInfo: [AnyHashable: Any] = [:]
        if let stationId = outcome.chargingStationId,
            let modeRaw = outcome.chargingModeRaw
        {
            userInfo[Self.terminatedChargingStationIdKey] = stationId
            userInfo[Self.terminatedChargingModeRawKey] = modeRaw
        }
        NotificationCenter.default.post(
            name: Self.automationTerminatedNotification,
            object: nil,
            userInfo: userInfo
        )
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

        // The scheduled push is pointless now — the run is over.
        Task { await WakeScheduleClient.cancelActive() }
        WakeWindowCoordinator.shared.refresh()

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
        // Shared with the Notification Service Extension (ADR-006) so a
        // push-triggered run and the app see the same state. Falls back to
        // `UserDefaults.standard` while the App Group is unavailable.
        let defaults = AutomationSharedStore.defaults
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
        // One-shot move of pre-story-#9 state into the App Group. Runs before
        // the first read so an automation that was started by an older build
        // survives the upgrade.
        AutomationSharedStore.migrateDefaultsKeyIfNeeded(stateStorageKey)
        AutomationSharedStore.migrateDefaultsKeyIfNeeded(parametersStorageKey)

        let defaults = AutomationSharedStore.defaults
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

    /// The title is the automation's name, not "… finished/cancelled/stopped":
    /// those read as truncated ("Lademodus Auto-Reset abgesch…") in a banner
    /// in every language, and repeated what the body already says.
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
                localized: "Auto-reset Charging Mode"
            )
            content.body = String(
                localized:
                    "Charging mode reset to \(modeName)."
            )
        case .cancelled:
            content.title = String(
                localized: "Auto-reset Charging Mode"
            )
            content.body = String(
                localized:
                    "Cancelled by you. Charging station switched to \(modeName)."
            )
        case .failed:
            content.title = String(
                localized: "Auto-reset Charging Mode"
            )
            content.body = String(
                localized:
                    "Couldn't apply the charging-mode change. Please verify the charging station state in the Solar Manager app."
            )
        case .userOverride:
            content.title = String(
                localized: "Auto-reset Charging Mode"
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
                localized: "Auto-reset Charging Mode"
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
