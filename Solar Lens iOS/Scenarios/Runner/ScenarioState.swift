import Foundation

public struct ScenarioState: Codable {
    var scenario: Scenario? = nil
    var status: ScenarioStatus = .none
    var nextTaskRun: Date? = nil

    // Scenario-specific states
    var batteryToCar: ScenarioBatteryToCarState? = nil

    init() {
    }

    init(
        scenario: Scenario,
        status: ScenarioStatus,
        nextTaskRun: Date?,
        batteryToCar: ScenarioBatteryToCarState?
    ) {
        self.scenario = scenario
        self.status = status
        self.nextTaskRun = nextTaskRun
        self.batteryToCar = batteryToCar
    }

    init(scenario: Scenario) {
        self.scenario = scenario
    }
}
