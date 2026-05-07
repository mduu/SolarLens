public enum Automation: String, Codable {
    case BatteryToCar
}

extension Automation {

    func getAutomationTask() -> AutomationTask? {
        switch self {
        case .BatteryToCar:
            return AutomationBatteryToCar.shared
        }
    }

}
