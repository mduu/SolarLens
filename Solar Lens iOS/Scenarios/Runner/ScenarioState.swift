import Foundation

public struct ScenarioState: Codable {
    var scenario: Scenario? = nil
    var status: ScenarioStatus = .none
    var nextTaskRun: Date? = nil

    // Scenario-specific states
    var batteryToCar: ScenarioBatteryToCarState? = nil
    var oneTimeTariff: ScenarioOneTimeTariffState? = nil

    init() {
    }

    init(
        scenario: Scenario,
        status: ScenarioStatus,
        nextTaskRun: Date?,
        batteryToCar: ScenarioBatteryToCarState? = nil,
        oneTimeTariff: ScenarioOneTimeTariffState? = nil
    ) {
        self.scenario = scenario
        self.status = status
        self.nextTaskRun = nextTaskRun
        self.batteryToCar = batteryToCar
        self.oneTimeTariff = oneTimeTariff
    }

    init(scenario: Scenario) {
        self.scenario = scenario

        switch scenario {
        case .BatteryToCar:
            batteryToCar = .init()
        case .OneTimeTariff:
                oneTimeTariff = .init()
        }
    }

    func failed() -> ScenarioState {
        return .init(
            scenario: scenario!,
            status: .failed,
            nextTaskRun: nil as Date?,
            batteryToCar: nil as ScenarioBatteryToCarState?,
            oneTimeTariff: nil as ScenarioOneTimeTariffState?
        )
    }
}
