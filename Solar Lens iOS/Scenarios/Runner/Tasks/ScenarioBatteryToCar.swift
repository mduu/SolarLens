import BackgroundTasks
import Foundation
import UIKit

final class ScenarioBatteryToCar: ScenarioTask {
    public static let shared = ScenarioBatteryToCar()

    let scenarioName: LocalizedStringResource = "Battery to Car"
    let fiveMinutes: TimeInterval = 5 * 60

    func run<TParameters: ScenarioTaskParameters, TState: ScenarioTaskState>(
        host: any ScenarioHost,
        parameters: TParameters,
        state: TState
    )
        async throws -> ScenarioTaskRunResult
    {
        let params = parameters as ScenarioBatteryToCarParameters

        let numberOfWork = state.numberOfWork + 1

        host.logInfo(message: "Battery to car: Doing work #\(numberOfWork)")

        // TODO Do work

        if numberOfWork < 2 {
            host.logInfo(message: "Battery to car: scheduled next call")
            let nextRun = Date().addingTimeInterval(fiveMinutes)

            return ScenarioTaskRunResult(
                nextRunAfter: nextRun,
                newStatus: ScenarioStatus.finishedSuccessfull,
                newState: ScenarioBatteryToCarState(
                    from: state,
                    numberOfWork: numberOfWork,
                    isStopped: false
                )
            )
        }

        host.logSuccess()

        return ScenarioTaskRunResult(
            nextRunAfter: nil as Date?,
            newStatus: ScenarioStatus.finishedSuccessfull,
            newState: nil as ScenarioBatteryToCarState?
        )
    }

}

class ScenarioBatteryToCarParameters: ScenarioTaskParameters, Codable {
    var minBatteryLevel: Int = 20
}

class ScenarioBatteryToCarState: ScenarioTaskState, Codable {
    var numberOfWork: Int = 0
    var isStopped: Bool = false

    convenience init(
        from other: ScenarioBatteryToCarState,
        numberOfWork: Int? = nil,
        isStopped: Bool? = nil
    ) {
        self.init()  // Call the designated initializer (or a default one if available)
        self.numberOfWork = numberOfWork ?? other.numberOfWork
        self.isStopped = isStopped ?? other.isStopped
    }
}
