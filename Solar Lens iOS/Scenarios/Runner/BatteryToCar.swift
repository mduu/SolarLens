import BackgroundTasks
import Foundation

class ScenarioBatteryToCar {
    public let identifier =
        "com.marcduerst.SolarManagerWatch.Scenario.BatteryToCar"
    
    private var numberOfWork: Int = 0

    func register() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: identifier,
            using: nil
        ) { task in
            self.handle(task: task as! BGProcessingTask)
        }
    }

    func start() {
        scheduleNextCall()
    }

    func handle(task: BGProcessingTask) {
        // Schedule a new refresh task.
        //scheduleNextCall()

        // Provide the background task with an expiration handler that cancels the operation.
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
            self.scheduleNextCall()
        }

        /// Perform longer work
        Task {
            // Your background processing here
            let success = await doWork()

            if success {
                task.setTaskCompleted(success: success)
            } else {
                scheduleNextCall()
            }
        }
    }

    private func scheduleNextCall() {
        let request = BGAppRefreshTaskRequest(identifier: identifier)

        let minutes: Int = 5
        request.earliestBeginDate = Date(
            timeIntervalSinceNow: TimeInterval(minutes * 60)
        )

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }

    private func doWork() async -> Bool {
        numberOfWork += 1
        
        print("Battery to car: Doing work #\(numberOfWork)")
        
        // TODO Do work

        if numberOfWork < 2 {
            return false
        }
        return true
    }
}
