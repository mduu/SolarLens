import Foundation

struct BatteryInfo: Sendable {
    let favorite: Bool
    let maxDischargePower: Int
    let maxChargePower: Int
    let batteryCapacityKwh: Double

    let modeInfo: BatteryModeInfo
}

struct BatteryModeInfo: Sendable {
    let batteryChargingMode: BatteryChargingMode
    let batteryMode: BatteryMode
    let batteryManualMode: BatteryManualMode
    let upperSocLimit: Int
    let lowerSocLimit: Int
    let dischargeSocLimit: Int
    let chargingSocLimit: Int
    let morningSocLimit: Int
    let peakShavingSocDischargeLimit: Int
    let peakShavingSocMaxLimit: Int
    let peakShavingMaxGridPower: Int
    let peakShavingRechargePower: Int
    let tariffPriceLimitSocMax: Int
    let tariffPriceLimit: Double
    let tariffPriceLimitForecast: Bool
    let standardStandaloneAllowed: Bool
    let standardLowerSocLimit: Int
    let standardUpperSocLimit: Int
    let powerCharge: Int
    let powerDischarge: Int

    func createClone(
        batteryChargingMode: BatteryChargingMode? = nil,
        batteryMode: BatteryMode? = nil,
        batteryManualMode: BatteryManualMode? = nil,
        upperSocLimit: Int? = nil,
        lowerSocLimit: Int? = nil,
        dischargeSocLimit: Int? = nil,
        chargingSocLimit: Int? = nil,
        morningSocLimit: Int? = nil,
        peakShavingSocDischargeLimit: Int? = nil,
        peakShavingSocMaxLimit: Int? = nil,
        peakShavingMaxGridPower: Int? = nil,
        peakShavingRechargePower: Int? = nil,
        tariffPriceLimitSocMax: Int? = nil,
        tariffPriceLimit: Double? = nil,
        tariffPriceLimitForecast: Bool? = nil,
        standardStandaloneAllowed: Bool? = nil,
        standardLowerSocLimit: Int? = nil,
        standardUpperSocLimit: Int? = nil,
        powerCharge: Int? = nil,
        powerDischarge: Int? = nil
    ) -> BatteryModeInfo {

        return BatteryModeInfo(
            batteryChargingMode: batteryChargingMode
                ?? self.batteryChargingMode,
            batteryMode: batteryMode ?? self.batteryMode,
            batteryManualMode: batteryManualMode ?? self.batteryManualMode,
            upperSocLimit: upperSocLimit ?? self.upperSocLimit,
            lowerSocLimit: lowerSocLimit ?? self.lowerSocLimit,
            dischargeSocLimit: dischargeSocLimit ?? self.dischargeSocLimit,
            chargingSocLimit: chargingSocLimit ?? self.chargingSocLimit,
            morningSocLimit: morningSocLimit ?? self.morningSocLimit,
            peakShavingSocDischargeLimit: peakShavingSocDischargeLimit
                ?? self.peakShavingSocDischargeLimit,
            peakShavingSocMaxLimit: peakShavingSocMaxLimit
                ?? self.peakShavingSocMaxLimit,
            peakShavingMaxGridPower: peakShavingMaxGridPower
                ?? self.peakShavingMaxGridPower,
            peakShavingRechargePower: peakShavingRechargePower
                ?? self.peakShavingRechargePower,
            tariffPriceLimitSocMax: tariffPriceLimitSocMax
                ?? self.tariffPriceLimitSocMax,
            tariffPriceLimit: tariffPriceLimit ?? self.tariffPriceLimit,
            tariffPriceLimitForecast: tariffPriceLimitForecast
                ?? self.tariffPriceLimitForecast,
            standardStandaloneAllowed: standardStandaloneAllowed
                ?? self.standardStandaloneAllowed,
            standardLowerSocLimit: standardLowerSocLimit
                ?? self.standardLowerSocLimit,
            standardUpperSocLimit: standardUpperSocLimit
                ?? self.standardUpperSocLimit,
            powerCharge: powerCharge ?? self.powerCharge,
            powerDischarge: powerDischarge ?? self.powerDischarge
        )
    }
}

// Old V1
enum BatteryChargingMode: Int {
    case Passive = 0
    case Active = 1
    case Charge = 2
    case Discharge = 3
    case Off = 4

    static func from(_ value: Int?) -> BatteryChargingMode {
        return BatteryChargingMode(rawValue: value ?? 0) ?? .Passive
    }
}

// New V2
enum BatteryMode: Int {
    case Standard = 0
    case Eco = 1
    case PeakShaving = 2
    case Manual = 3
    case TariffOptimized = 4
    case StandardControlled = 5

    static func from(_ value: Int?) -> BatteryMode {
        return BatteryMode(rawValue: value ?? 0) ?? .StandardControlled
    }

    func GetBatteryModeName() -> LocalizedStringResource {
        switch self {
        case .Standard: return "Standard"
        case .Eco: return "Eco"
        case .PeakShaving: return "Peak Shaving"
        case .Manual: return "Manual"
        case .TariffOptimized: return "Tariff optimized"
        case .StandardControlled: return "Standard"
        }
    }
}

enum BatteryManualMode: Int, CaseIterable, Identifiable {
    case Charge = 0
    case Discharge = 1
    case Off = 2
    
    var id: Int { self.rawValue } // Use rawValue as a unique ID

    static func from(_ value: Int?) -> BatteryManualMode {
        return BatteryManualMode(rawValue: value ?? 0) ?? .Charge
    }
}

extension BatteryManualMode {
    var localizedName: LocalizedStringResource {
        switch self {
        case .Charge: return "battery_manualmode_charge"
        case .Discharge: return "battery_manualmode_discharge"
        case .Off: return "battery_manualmode_off"
        }
    }
}

extension BatteryInfo {

    static func fake() -> BatteryInfo {
        return BatteryInfo(
            favorite: true,
            maxDischargePower: 7000,
            maxChargePower: 7000,
            batteryCapacityKwh: 14,
            modeInfo: BatteryModeInfo.fake()
        )
    }

}

extension BatteryModeInfo {

    static func fake() -> BatteryModeInfo {
        return BatteryModeInfo(
            batteryChargingMode: BatteryChargingMode.from(nil),
            batteryMode: BatteryMode.from(nil),
            batteryManualMode: BatteryManualMode.from(nil),

            upperSocLimit: 95,
            lowerSocLimit: 15,

            dischargeSocLimit: 0,
            chargingSocLimit: 0,
            morningSocLimit: 30,

            peakShavingSocDischargeLimit: 100,
            peakShavingSocMaxLimit: 80,
            peakShavingMaxGridPower: 10,
            peakShavingRechargePower: 40,

            tariffPriceLimitSocMax: 0,
            tariffPriceLimit: 0.23,
            tariffPriceLimitForecast: false,

            standardStandaloneAllowed: false,
            standardLowerSocLimit: 10,
            standardUpperSocLimit: 90,

            powerCharge: 10,
            powerDischarge: 90,
        )

    }
}
