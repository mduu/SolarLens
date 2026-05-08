// The `Automation` enum itself lives in `Shared/Automations/Automation.swift`
// so the iOS Live Activity widget extension can reference it. Only the
// runtime task-lookup extension stays here — `AutomationTask` and the runner
// are iOS-app-target-only.

extension Automation {

    func getAutomationTask() -> AutomationTask? {
        switch self {
        case .BatteryToCar:
            return AutomationBatteryToCar.shared
        case .AutoResetChargingMode:
            return AutomationAutoResetChargingMode.shared
        case .NotifyOnBatteryLevel:
            return AutomationNotifyOnBatteryLevel.shared
        }
    }

}
