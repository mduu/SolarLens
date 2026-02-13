internal import Foundation
struct SensorInfosV1Response : Codable {
    var _id: String
    var device_type: String // device, smart-meter, inverter, car, input-device, sub-meter
    var type: String // Battery, Car Charging, Energy Measurement, Heatpump, Car, Input Device
    var device_group: String // Name of the device
    var name: String? // Cars seem to have the name on this lavel; not in the tags
    var priority: Int
    var signal: SensorConnectionStatus = .notConnected
    var deviceActivity: Int?
    var soc: Double? // Car: Battery-Level
    var errorCodes: [ErrorCode] = []
    var ip: String?
    var mac: String?
    var createdAt: String?
    var updatedAt: String?
    var tag: SensorInfosV1Tag?
    var data: SensorInfosV1Data?
    //var strings: []

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decode(String.self, forKey: ._id)
        device_type = (try? container.decode(String.self, forKey: .device_type)) ?? "unknown"
        type = (try? container.decode(String.self, forKey: .type)) ?? "unknown"
        device_group = (try? container.decode(String.self, forKey: .device_group)) ?? ""
        name = try? container.decode(String.self, forKey: .name)
        priority = (try? container.decode(Int.self, forKey: .priority)) ?? 999
        signal = (try? container.decode(SensorConnectionStatus.self, forKey: .signal)) ?? .unknown
        deviceActivity = try? container.decode(Int.self, forKey: .deviceActivity)
        soc = try? container.decode(Double.self, forKey: .soc)
        errorCodes = (try? container.decode([ErrorCode].self, forKey: .errorCodes)) ?? []
        ip = try? container.decode(String.self, forKey: .ip)
        mac = try? container.decode(String.self, forKey: .mac)
        createdAt = try? container.decode(String.self, forKey: .createdAt)
        updatedAt = try? container.decode(String.self, forKey: .updatedAt)
        tag = try? container.decode(SensorInfosV1Tag.self, forKey: .tag)
        data = try? container.decode(SensorInfosV1Data.self, forKey: .data)
    }
    
    /// Map the string value to a proper enum
    var deviceType: SensorType {
        
        switch device_type.lowercased() {
        case "device":
            return .device
        case "car":
            return .car
        case "inverter":
            return .inverter
        case "smart-meter":
            return .smartMeter
        case "input-device":
            return .other
        default:
            return .other
        }
    }
    
    func getSensorName() -> String {
        return name ?? tag?.name ?? device_group
    }
    
    func hasErrors() -> Bool {
        return errorCodes.count > 0
    }
    
    func isCarCharging() -> Bool {
        return isDevice() && type.caseInsensitiveCompare("Car Charging") == .orderedSame
    }
    
    func isBattery() -> Bool {
        return isDevice() && type
            .caseInsensitiveCompare("Battery") == .orderedSame
    }
    
    func isDevice() -> Bool {
        return deviceType == .device
    }
    
    func isCar() -> Bool {
        return deviceType == .car
    }
}

struct SensorInfosV1Tag: Codable {
    var name: String?
    var color: String?
    var sensorsCount: Int?
}

struct SensorInfosV1Data: Codable {
    var batteryCapacity: Double?
    var batteryChargingMode: Int?
    var batteryMode: Int?
    var batteryManualMode: Int?
    var upperSocLimit: Double?
    var lowerSocLimit: Double?
    var dischargeSocLimit: Double?
    var chargingSocLimit: Double?
    var morningSocLimit: Double?
    var peakShavingSocDischargeLimit: Double?
    var peakShavingSocMaxLimit: Double?
    var peakShavingMaxGridPower: Double?
    var peakShavingRechargePower: Double?
    var tariffPriceLimitSocMax: Double?
    var tariffPriceLimit: Double?
    var tariffPriceLimitForecast: Bool?
    var standardStandaloneAllowed: Bool?
    var standardLowerSocLimit: Double?
    var standardUpperSocLimit: Double?
    var powerCharge: Double?
    var powerDischarge: Double?

    var favorite: Bool?
    var maxDischargePower: Double?
    var maxChargePower: Double?
}
