public struct AutomationParameters: Codable {
    var batteryToCar: AutomationBatteryToCarParameters? = nil
    var autoResetChargingMode: AutomationAutoResetChargingModeParameters? = nil
    var notifyOnBatteryLevel: AutomationNotifyOnBatteryLevelParameters? = nil
}
