struct SensorInfosV1Response : Codable {
    var _id: String
    var device_type: SensorType // device, smart-meter, inverter
    var type: String // Battery, Car Charging, Energy Measurement
    var device_group: String // Name of the device
    var priority: Int
    var signal: SensorConnectionStatus
    var deviceActivity: Int
    var errorCodes: [String]
    var ip: String?
    var mac: String?
    var createdAt: String?
    var updatedAt: String?
    var tag: SensorInfosV1Tag?
    //var data: []
    //var strings: []
    
    func isCarCharging() -> Bool {
        return isDevice() && type == "Car Charging"
    }
    
    func isBattery() -> Bool {
        return isDevice() && type == "Battery"
    }
    
    func isDevice() -> Bool {
        return device_type == .device
    }
}

struct SensorInfosV1Tag: Codable {
    var name: String
    var color: String?
}
