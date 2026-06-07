internal import Foundation

public struct AutomationState: Codable, Sendable {
    var automation: Automation? = nil
    var status: AutomationStatus = .none
    var nextTaskRun: Date? = nil

    // Automation-specific states
    var batteryToCar: AutomationBatteryToCarState? = nil
    var autoResetChargingMode: AutomationAutoResetChargingModeState? = nil

    init() {
    }

    init(
        automation: Automation,
        status: AutomationStatus,
        nextTaskRun: Date?,
        batteryToCar: AutomationBatteryToCarState? = nil,
        autoResetChargingMode: AutomationAutoResetChargingModeState? = nil
    ) {
        self.automation = automation
        self.status = status
        self.nextTaskRun = nextTaskRun
        self.batteryToCar = batteryToCar
        self.autoResetChargingMode = autoResetChargingMode
    }

    init(automation: Automation) {
        self.automation = automation

        switch automation {
        case .BatteryToCar:
            batteryToCar = .init()
        case .AutoResetChargingMode:
            autoResetChargingMode = .init()
        }
    }

    func failed() -> AutomationState {
        return .init(
            automation: automation!,
            status: .failed,
            nextTaskRun: nil as Date?,
            batteryToCar: nil as AutomationBatteryToCarState?,
            autoResetChargingMode:
                nil as AutomationAutoResetChargingModeState?
        )
    }
}
