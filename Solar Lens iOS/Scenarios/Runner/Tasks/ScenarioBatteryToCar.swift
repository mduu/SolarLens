import BackgroundTasks
import UIKit
import Foundation

class ScenarioBatteryToCar: ScenarioTask {
    public static let shared = ScenarioBatteryToCar()

    var scenarioName: LocalizedStringResource = "Battery to Car"

    private var numberOfWork: Int = 0
    private var isStopped: Bool = false

    func run(host: any ScenariorHost) async throws -> TimeInterval? {
        numberOfWork += 1

        host.logInfo(message: "Battery to car: Doing work #\(numberOfWork)")

        // TODO Do work

        if numberOfWork < 2 {
            host.logInfo(message: "Battery to car: scheduled next call")
            let fiveMinutes: TimeInterval = 5 * 60
            return fiveMinutes
        }

        host.logSuccess()
        return nil
    }
}
