import BackgroundTasks
import Foundation

public class ScenarioManager: ScenariorHost {

    public static var shared: ScenarioManager = .init()

    public var activeScenario: Scenario?
    public var log: [ScenarioLogMessage] = []

    private let identifier =
        "com.marcduerst.SolarManagerWatch.ScenarioRunner"
    private var activeTask: ScenarioTask?
    private var nextRun: Date?
    
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
    
    public func startScenario(scenario: Scenario) {
        switch scenario {
        case .BatteryToCar:
            activeTask = ScenarioBatteryToCar()
            break
        default:
            logError(message: "Unsupported scenario \(scenario.rawValue)")
        }
        
        activeScenario = scenario
        
        logInfo(message: "Scenario \(activeScenarioName) started")
        
        Task {
            await runActiveScenario()
        }
    }

    func logSccess() {
        log.append(
            .init(
                time: Date(),
                message: "Successfully ran scenario \(activeScenarioName).)",
                level: .Success
            )
        )
    }

    func logInfo(message: LocalizedStringResource) {
        log.append(.init(time: Date(), message: message, level: .Info))
    }

    func logError(message: LocalizedStringResource) {
        log.append(.init(time: Date(), message: message, level: .Error))
    }
    
    func logDebug(message: LocalizedStringResource) {
        log.append(.init(time: Date(), message: message, level: .Debug))
    }

    func logFailure() {
        log.append(.init(
            time: Date(),
            message: "Scenario \(activeScenarioName) failed!",
            level: .Failure))
    }

    private var foregroundCheckTask: Task<Void, Never>? = nil

    func handleBckgroundTask(task: BGAppRefreshTask) {
        logDebug(message: "Background trigger received")

        if activeTask == nil {
            logInfo(message: "Background trigger received but active scenario. Abort background task.")

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
        guard let nextRun else {
            logError(message: "No 'nextRun' date set, cannot schedule background task")
            return
        }

        let request = BGAppRefreshTaskRequest(identifier: identifier)

        let now: Date = Date()
        let nextRunIn = nextRun.timeIntervalSince(now)

        request.earliestBeginDate = Date(
            timeIntervalSinceNow: nextRunIn
        )

        do {
            
            try BGTaskScheduler.shared.submit(request)
            logDebug(message: "Next background check scheduled successfully at \(nextRunIn)")
            
        } catch {
            logError(
                message: "ERROR: Could not schedule app refresh: \(error.localizedDescription)"
            )
        }
    }

    private func runActiveScenario() async {
        let maxRetries = 3
        var currentRetry = 0

        while currentRetry <= maxRetries {
            do {
                logDebug(message: "Run scenario \(activeScenarioName)")

                let nextRunIn = try await activeTask?.run(host: self)

                if nextRunIn != nil {
                    nextRun = Date().addingTimeInterval(nextRunIn!)
                    logDebug(
                        message: "Next scenario run at \(activeScenarioName)"
                    )
                } else {
                    scenarioFinished()
                }

                return  // Exit the function immediately on success
            } catch {
                currentRetry += 1
                logError(
                    message: "RunActiveScenario: activeTask?.run() failed (attempt \(currentRetry)/\(maxRetries + 1)). Error: \(error.localizedDescription)"
                )

                if currentRetry <= maxRetries {
                    logDebug(message: "RunActiveScenario: Retrying in 1 second...")
                    try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second
                } else {
                    // All retries exhausted, re-throw the last error or handle it
                    logError(
                        message: "RunActiveScenario: All \(maxRetries + 1) attempts failed."
                    )
                    // If you want to propagate the error up, uncomment the line below.
                    // Otherwise, you might log it and decide on a different action.
                    // throw error // Uncomment to re-throw the error
                    // For this example, we'll just log and gracefully exit if no further action needed
                    return
                }
            }
        }
    }

    private func scenarioFinished() {
        logDebug(message: "Scenarion \(activeScenarioName)")

        activeScenario = nil
        activeTask = nil
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier)
    }
}
