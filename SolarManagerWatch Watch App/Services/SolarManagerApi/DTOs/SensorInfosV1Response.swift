//
//  SensorInfosResponse.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 21.10.2024.
//

struct SensorInfosV1Response : Codable {
    var _id: String
    var device_type: String // device, smart-meter, inverter
    var type: String // Battery, Smart Meter, Car Charging, Inverter
    var device_group: String // Name of the device
    var priority: Int
    var signal: SensorConnectionStatus
    var deviceActivity: Int
    var errorCodes: [String]
    var ip: String?
    var mac: String?
    var createdAt: String?
    var updatedAt: String?
    //var tags: {}
    //var data: []
    //var strings: []
    
    func isCarCharging() -> Bool {
        return device_type == "device" && type == "Car Charging"
    }
    
    func isBattery() -> Bool {
        return device_type == "device" && type == "Battery"
    }
}
