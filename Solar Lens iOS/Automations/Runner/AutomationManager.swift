import BackgroundTasks
internal import Foundation
import SwiftUI
import UserNotifications

@Observable
@MainActor
public final class AutomationManager: AutomationHost {

    public static let shared: AutomationManager = AutomationManager()

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
            logError(message: "Cannot start: another automation is running")
            return
        }

        activeState = AutomationState(automation: automation)
        activeTaskParameters = parameters
        persistState()

        logInfo(message: "Automation \(activeAutomationName) started")

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
        logInfo(message: "Automation \(activeAutomationName) cancelled by user")

        Task {
            // Best-effort: switch wallbox to fallback mode.
            if let p = params.batteryToCar {
                _ = try? await self.energyManager.setCarChargingMode(
                    sensorId: p.chargingDeviceId,
                    carCharging: ControlCarChargingRequest(
                        chargingMode: p.fallbackChargingMode
                    )
                )
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
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60)

        do {
            try BGTaskScheduler.shared.submit(request)
            logDebug(message: "Next background check scheduled (~60s)")
        } catch {
            logError(
                message:
                    "Could not schedule app refresh: \(error.localizedDescription)"
            )
        }
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

                if newState.status == .finishedSuccessful {
                    let reason = mapStopReason(
                        newState.batteryToCar?.stopReason
                    )
                    terminateAutomation(reason: reason)
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
        case failed
    }

    private func mapStopReason(
        _ reason: AutomationBatteryToCarStopReason?
    ) -> TerminationReason {
        switch reason {
        case .softFloorReached: return .softFloorReached
        case .capped:           return .capped
        case .cancelled:        return .cancelled
        case .none:             return .softFloorReached
        }
    }

    private func terminateAutomation(reason: TerminationReason) {
        let snapshot = activeState
        let snapshotParams = activeTaskParameters

        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier)
        stopTimer()

        postFinishedNotification(
            reason: reason,
            state: snapshot,
            params: snapshotParams
        )

        activeState = nil
        activeTaskParameters = nil
        persistState()
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
        guard let s = state?.batteryToCar,
              let p = params?.batteryToCar else { return }

        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.sound = .default

        let kwh = String(format: "%.1f", s.kWhTransferred)
        let endSoc = s.endSoc ?? s.lastBatteryPercentage ?? 0
        let modeName = String(
            localized: p.fallbackChargingMode.localizedTitle
        )

        switch reason {
        case .softFloorReached:
            content.title = String(
                localized: "Battery-to-Car finished"
            )
            content.body = String(
                localized:
                    "≈ \(kwh) kWh transferred from battery (\(s.startSoc)% → \(endSoc)%). Wallbox switched to \(modeName)."
            )
        case .capped:
            content.title = String(
                localized: "Battery-to-Car stopped"
            )
            content.body = String(
                localized:
                    "Stopped to avoid grid import. ≈ \(kwh) kWh transferred (\(s.startSoc)% → \(endSoc)%). Wallbox switched to \(modeName)."
            )
        case .cancelled:
            content.title = String(
                localized: "Battery-to-Car cancelled"
            )
            content.body = String(
                localized:
                    "Cancelled by you. ≈ \(kwh) kWh transferred so far. Wallbox switched to \(modeName)."
            )
        case .failed:
            content.title = String(
                localized: "Battery-to-Car stopped"
            )
            content.body = String(
                localized:
                    "An error occurred while monitoring. Wallbox should now be on \(modeName)."
            )
        }

        let req = UNNotificationRequest(
            identifier: "automation.batteryToCar.\(UUID().uuidString)",
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
