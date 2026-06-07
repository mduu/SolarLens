public struct AutomationParameters: Codable, Sendable {
    var batteryToCar: AutomationBatteryToCarParameters? = nil
    var autoResetChargingMode: AutomationAutoResetChargingModeParameters? = nil
}
