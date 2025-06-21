import BackgroundTasks
import Foundation

class ScenarioBatteryToCar {
    public let identifier =
        "com.marcduerst.SolarManagerWatch.Scenario.BatteryToCar"

    func register() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: identifier,
            using: nil
        ) { task in
            self.handle(task: task as! BGProcessingTask)
        }
    }

    func start() {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        // Fetch no earlier than 15 minutes from now.
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }

    func handle(task: BGProcessingTask) {
        // Schedule a new refresh task.
        //scheduleAppRefresh()

        // Provide the background task with an expiration handler that cancels the operation.
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        /// Perform longer work
        Task {
            // Your background processing here
            let success = await performBackgroundProcessing()
            
            task.setTaskCompleted(success: success)
        }
    }
    
    func doWork() async -> Bool {
        return true;
    }
}
