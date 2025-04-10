struct SensorInfosV1Response : Codable {
    var _id: String
    var device_type: String // device, smart-meter, inverter, car
    var type: String // Battery, Car Charging, Energy Measurement, Heatpump, Car
    var device_group: String // Name of the device
    var priority: Int
    var signal: SensorConnectionStatus
    var deviceActivity: Int
    var soc: Int? // Car: Battery-Level
    var errorCodes: [String]
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
        default:
            return .other
        }
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
}

struct SensorInfosV1Tag: Codable {
    var name: String
    var color: String?
}

struct SensorInfosV1Data: Codable {
    var batteryCapacity: Int?
    var favorite: Bool?
}
