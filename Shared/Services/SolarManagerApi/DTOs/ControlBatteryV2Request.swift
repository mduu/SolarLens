struct ControlBatteryChargingV2Request: Codable {

    /// minimum: 0, maximum: 5
    var batteryMode: Int
    
    /// minimum: 0, maximum: 2
    var batteryManualMode: Int?
    
    /// default: 95, minimum: 0, maximum: 100
    var upperSocLimit: Int?

    /// default: 15, minimum: 0, maximum: 100
    var lowerSocLimit: Int?
    
    // minimum: 0
    var powerCharge: Int?
    
    /// minimum: 0
    var powerDischarge: Int?
    
    /// default: 80, minimum: 0, maximum: 100
    var dischargeSocLimit: Int?
    
    /// default: 100, minimum: 0, maximum: 100
    var chargingSocLimit: Int?
    
    /// default: 10, minimum: 0, maximum: 100
    var peakShavingSocDischargeLimit: Int?
    
    /// default: 40, minimum: 0, maximum: 100
    var peakShavingSocMaxLimit: Int?
    
    /// default: 0, minimum: 0
    var peakShavingMaxGridPower: Int?
    
    /// default: 0, minimum: 0
    var peakShavingRechargePower: Int?
    
    var tariffPriceLimit: Double?
    
    /// minimum: 0, maximum: 100
    var tariffPriceLimitSocMax: Int?
    
    var tariffPriceLimitForecast: Bool?
    
    /// default: false
    var standardStandaloneAllowed: Bool?
    
    /// default: 10, minimum: 0, maximum: 100
    var standardLowerSocLimit: Int?
    
    /// default: 90, minimum: 0, maximum: 100
    var standardUpperSocLimit: Int?
}
