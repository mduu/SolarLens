import BackgroundTasks
import Foundation

public final class ScenarioManager: ScenarioHost {

    public static var shared: ScenarioManager = .init()

    public var activeScenario: Scenario?

    private let identifier =
        "com.marcduerst.SolarManagerWatch.ScenarioRunner"

    private var activeTask: ScenarioTask?
    private var activeTaskStatus: ScenarioStatus = .none
    private var activeTaskParameters: any ScenarioTaskParameters?
    private var activeTaskState: any ScenarioTaskState?
    private var activeTaskNextRun: Date?

    private var activeScenarioName: LocalizedStringResource {
        activeTask?.scenarioName ?? "-"
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

    public func startScenario(
        scenario: Scenario,
        parameters: any ScenarioTaskParameters
    ) {
        switch scenario {
        case .BatteryToCar:
            activeTask = ScenarioBatteryToCar.shared
            activeTaskState = ScenarioBatteryToCarState()
            break
        default:
            logError(message: "Unsupported scenario \(scenario.rawValue)")
        }

        activeScenario = scenario
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

    private var foregroundCheckTask: Task<Void, Never>? = nil

    func handleBckgroundTask(task: BGAppRefreshTask) {
        logDebug(message: "Background trigger received")

        if activeTask == nil {
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

            if activeScenario != nil {
                scheduleNextBackgroundCall()
            }
        }
    }

    private func scheduleNextBackgroundCall() {
        guard let activeTaskNextRun else {
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
        guard let activeTask else {
            return
        }

        let maxRetries = 10
        var currentRetry = 0

        while currentRetry <= maxRetries {
            do {
                logDebug(message: "Run scenario \(activeScenarioName)")

                let runResult = try await activeTask.run(
                    host: self,
                    parameters: activeTaskParameters
                )

                if runResult.nextRunAfter != nil {
                    activeTaskNextRun = runResult.nextRunAfter
                    
                    logDebug(
                        message: "Next scenario '\(activeScenarioName)' run at \(activeTaskNextRun)"
                    )
                } else {
                    scenarioFinished()
                }

                return  // Exit the function immediately on success
            } catch {
                currentRetry += 1
                logError(
                    message:
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

                    activeTaskState?.stat

                    return
                }
            }
        }
    }

    private func scenarioFinished() {
        logDebug(message: "Scenarion \(activeScenarioName)")

        activeScenario = nil
        activeTaskStatus = .finishedSuccessfull
        activeTask = nil
        activeTaskParameters = nil
        activeTaskState = nil

        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier)
    }
}
