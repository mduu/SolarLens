public enum Scenario: String, Codable {
    case BatteryToCar
    case OneTimeTariff
}

extension Scenario {

    func getScenarioTask() -> ScenarioTask? {
        switch self {
        case .BatteryToCar:
            return ScenarioBatteryToCar.shared
        case .OneTimeTariff:
            return ScenarioBatteryToCar.shared  // TODO Change
        }
    }

}
