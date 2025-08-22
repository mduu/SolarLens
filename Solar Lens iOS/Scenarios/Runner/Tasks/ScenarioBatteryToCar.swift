import BackgroundTasks
import Foundation
import UIKit

final class ScenarioBatteryToCar: ScenarioTask {
    public static let shared = ScenarioBatteryToCar()

    let scenarioName: LocalizedStringResource = "Battery to Car"
    let fiveMinutes: TimeInterval = 5 * 60

    func run(
        host: any ScenarioHost,
        parameters: ScenarioParameters,
        state: ScenarioState
    )
        async throws -> ScenarioState
    {
        let previousNumberOfWork = state.batteryToCar?.numberOfWork ?? 0

        let numberOfWork = previousNumberOfWork + 1

        host.logInfo(message: "Battery to car: Doing work #\(numberOfWork)")

        // TODO Do work

        if numberOfWork < 2 {
            host.logInfo(message: "Battery to car: scheduled next call")
            let nextRun = Date().addingTimeInterval(fiveMinutes)

            return ScenarioState(
                scenario: state.scenario!,
                status: ScenarioStatus.running,
                nextTaskRun: nextRun,
                batteryToCar: ScenarioBatteryToCarState(
                    numberOfWork: numberOfWork,
                    isStopped: false
                )
            )
        }

        host.logSuccess()

        return ScenarioState(
            scenario: state.scenario!,
            status: ScenarioStatus.finishedSuccessful,
            nextTaskRun: nil as Date?,
            batteryToCar: nil as ScenarioBatteryToCarState?
        )
    }

}

class ScenarioBatteryToCarParameters: Codable {
    var minBatteryLevel: Int = 20
    
    init() {}
    
    init(minBatteryLevel: Int)
    {
        self.minBatteryLevel = minBatteryLevel
    }
}

class ScenarioBatteryToCarState: Codable {
    var numberOfWork: Int = 0
    var isStopped: Bool = false

    init() {
    }

    init(numberOfWork: Int, isStopped: Bool) {
        self.numberOfWork = numberOfWork
        self.isStopped = isStopped
    }
}
