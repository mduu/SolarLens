struct BatteryInfo: Sendable {
    let favorite: Bool
    let maxDischargePower: Int
    let maxChargePower: Int
    let batteryCapacityKwh: Double

    let batteryChargingMode: BatteryChargingMode = .Active
    let batteryMode: BatteryMode = .Standard
    let batteryManualMode: BatteryManualMode? = .Charge
    let upperSocLimit: Int = 95
    let lowerSocLimit: Int = 15
    let dischargeSocLimit: Int = 30
    let chargingSocLimit: Int = 100
    let morningSocLimit: Int = 80
    let peakShavingSocDischargeLimit: Int = 10
    let peakShavingSocMaxLimit: Int = 40
    let peakShavingMaxGridPower: Int = 0
    let peakShavingRechargePower: Int = 0
    let tariffPriceLimit: Double = 0
    let tariffPriceLimitSocMax: Int = 0
    let tariffPriceLimitForecast: Bool = false
    let standardStandaloneAllowed: Bool = false
    let standardLowerSocLimit: Int = 10
    let standardUpperSocLimit: Int = 90
    let powerCharge: Int = 0
    let powerDischarge: Int = 0
}

// Old V1
enum BatteryChargingMode {
    case Passive
    case Active
    case Charge
    case Discharge
    case Off
}

// New V2
enum BatteryMode {
    case Standard
    case Eco
    case PeakShaving
    case Manual
    case TariffOptimized
    case StandardControlled
}

enum BatteryManualMode {
    case Charge
    case Discharge
    case Off
}
