import BackgroundTasks
import SwiftUI
import Foundation

public final class ScenarioManager: ScenarioHost {

    public static var shared: ScenarioManager = .init()
    private let identifier =
        "com.marcduerst.SolarManagerWatch.ScenarioRunner"

    private var activeState: ScenarioState? = nil
    private var activeTaskParameters: ScenarioParameters? = nil
    private var activeScenarioName: LocalizedStringResource {
        activeState?.scenario?.getScenarioTask()?.scenarioName ?? "-"
    }
    private var timer: Timer?

    public var activeScenario: Scenario? {
        activeState?.scenario
    }

    public func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: identifier,
            using: nil
        ) { task in
            self.handleBckgroundTask(task: task as! BGAppRefreshTask)
        }

        logDebug(message: "Background tasks registered with iOS")
    }
    
    public func handleScenePhaseChange(_ oldPhase: ScenePhase, _ newPhase: ScenePhase)
    {
        switch newPhase {
        case .active:
            logDebug(message: "App became active")
        case .inactive:
            logDebug(message: "App became inactive")
        case .background:
            if activeState?.scenario == nil {
                logDebug(message: "App moved to background - no scenarion running")
            }
            
            logDebug(message: "App moved to background - scheduling background tasks")
            scheduleNextBackgroundCall()
        @unknown default:
            break
        }
    }

    public func startScenario(
        scenario: Scenario,
        parameters: ScenarioParameters
    ) {
        activeState = ScenarioState(scenario: scenario)
        activeTaskParameters = parameters

        logInfo(message: "Scenario \(activeScenarioName) started")

        Task {
            await runActiveScenario()
        }
    }

    func logSuccess() {
        ScenarioLogManager.shared.log(
            .init(
                message: "Successfully ran scenario \(activeScenarioName).",
                level: .Success
            )
        )
        print(
            "SCENARIO SUCCESS: Successfully ran scenario \(activeScenarioName)"
        )
    }

    func logInfo(message: LocalizedStringResource) {
        ScenarioLogManager.shared.log(
            .init(time: Date(), message: message, level: .Info)
        )
        print("SCENARIO INFO: \(message)")
    }

    func logError(message: LocalizedStringResource) {
        ScenarioLogManager.shared.log(
            .init(time: Date(), message: message, level: .Error)
        )

        print("SCENARIO ERROR: \(message)")
    }

    func logDebug(message: LocalizedStringResource) {
        ScenarioLogManager.shared.log(
            .init(time: Date(), message: message, level: .Debug)
        )
        print("SCENARIO DEBUG: \(message)")
    }

    func logFailure() {
        ScenarioLogManager.shared.log(
            .init(
                message: "Scenario \(activeScenarioName) failed!",
                level: .Failure
            )
        )
        print(
            "SCENARIO FAILURE: Successfully ran scenario \(activeScenarioName)"
        )
    }

    func handleBckgroundTask(task: BGAppRefreshTask) {
        logDebug(message: "Background trigger received")

        guard (activeState?.scenario?.getScenarioTask()) != nil else {
            logInfo(
                message:
                    "Background trigger received but active scenario. Abort background task."
            )

            task.setTaskCompleted(success: true)
            return
        }

        task.expirationHandler = {
            task.setTaskCompleted(success: false)
            self.scheduleNextBackgroundCall()
        }

        Task {
            await runActiveScenario()
            task.setTaskCompleted(success: true)

            if activeState?.scenario != nil {
                scheduleNextBackgroundCall()
            }
        }
    }
    
    func startTimer() {
        stopTimer()
        
        timer = Timer.scheduledTimer(withTimeInterval: 60.0 * 5, repeats: true) { [weak self] _ in
            guard let self else { return }
            
            let state = self.activeState
            
            guard let nextRunAfter = state?.nextTaskRun else {
                return
            }
            
            if nextRunAfter < Date() {
                Task {
                    await self.runActiveScenario()
                }
            }
        }
    }
    
    func stopTimer() {
        if let timer, timer.isValid {
            timer.invalidate()
        }
        timer = nil
    }

    private func scheduleNextBackgroundCall() {
        guard let activeTaskNextRun = activeState?.nextTaskRun else {
            logError(
                message:
                    "No 'nextRun' date set, cannot schedule background task"
            )
            return
        }

        let request = BGAppRefreshTaskRequest(identifier: identifier)

        let now: Date = Date()
        let nextRunIn = activeTaskNextRun.timeIntervalSince(now)

        request.earliestBeginDate = Date(
            timeIntervalSinceNow: nextRunIn
        )

        do {

            try BGTaskScheduler.shared.submit(request)
            logDebug(
                message:
                    "Next background check scheduled successfully at \(nextRunIn)"
            )

        } catch {
            logError(
                message:
                    "ERROR: Could not schedule app refresh: \(error.localizedDescription)"
            )
        }
    }

    private func runActiveScenario() async {
        guard let activeTask = activeState?.scenario?.getScenarioTask() else {
            logError(message: "No scenario task found!")
            return
        }

        guard let activeState else {
            logError(message: "No scenario state found!")
            return
        }

        guard let activeTaskParameters else {
            logError(
                message:
                    "No parameters provided for scenario \(activeScenarioName)"
            )
            return
        }

        let maxRetries = 10
        var currentRetry = 0

        while currentRetry <= maxRetries {
            do {
                logDebug(message: "Run scenario \(activeScenarioName)")

                let newState = try await activeTask.run(
                    host: self,
                    parameters: activeTaskParameters,
                    state: activeState
                )

                self.activeState = newState

                if activeState.nextTaskRun != nil {
                    logDebug(
                        message:
                            "Next scenario '\(activeScenarioName)' run at \(activeState.nextTaskRun!.description)"
                    )
                } else {
                    terminiateScenario()
                }

                return  // Exit the function immediately on success
            } catch {
                currentRetry += 1
                print(
                    "RunActiveScenario: activeTask?.run() failed (attempt \(currentRetry)/\(maxRetries + 1)). Error: \(error.localizedDescription)"
                )

                if currentRetry <= maxRetries {
                    logDebug(
                        message: "RunActiveScenario: Retrying in 1 second..."
                    )
                    try? await Task.sleep(nanoseconds: 2_000_000_000)  // 2 second
                } else {
                    // All retries exhausted, re-throw the last error or handle it
                    logError(
                        message:
                            "RunActiveScenario: All \(maxRetries + 1) attempts failed."
                    )
                    terminiateScenario()
                    return
                }
            }
        }
    }

    private func terminiateScenario() {
        logDebug(message: "Scenarion \(activeScenarioName) terminating")
        
        // TODO Push notification

        activeState = nil
        activeTaskParameters = nil

        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier)
        stopTimer()
    }
}
