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
    var name: String
    var color: String?
    var sensorsCount: Int?
}

struct SensorInfosV1Data: Codable {
    var batteryCapacity: Double?
    var batteryChargingMode: Int?
    var batteryMode: Int?
    var batteryManualMode: Int?
    var upperSocLimit: Int?
    var lowerSocLimit: Int?
    var dischargeSocLimit: Int?
    var chargingSocLimit: Int?
    var morningSocLimit: Int?
    var peakShavingSocDischargeLimit: Int?
    var peakShavingSocMaxLimit: Int?
    var peakShavingMaxGridPower: Int?
    var peakShavingRechargePower: Int?
    var tariffPriceLimitSocMax: Int?
    var tariffPriceLimit: Double?
    var tariffPriceLimitForecast: Bool?
    var standardStandaloneAllowed: Bool?
    var standardLowerSocLimit: Int?
    var standardUpperSocLimit: Int?
    var powerCharge: Int?
    var powerDischarge: Int?
    
    var favorite: Bool?
    var maxDischargePower: Int?
    var maxChargePower: Int?
}
