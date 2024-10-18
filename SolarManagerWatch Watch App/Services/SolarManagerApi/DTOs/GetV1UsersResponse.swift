//
//  GetV2UsersResponse.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 13.10.2024.
//

class V1User : Codable{
    var status: String  // active
    var language: String?  // Deutsch
    var last_name: String?
    var first_name: String?
    var email: String
    var country: String?
    var license: String?  // "Solar Premium"
    var city: String?
    var street: String?
    var zip: String?
    var kWp: Double?
    var energy_assistant_enable: Bool
    var user_id: String
    var registration_date: String? // "2024-09-20T08:15:54.138Z"
    var device_count: Int
    var car_count: Int
    var sm_id: String
    var gateway_id: String
    var installation_finished: Bool = false
    var hardware_version: String
    var firmware_version: String
    var signal: String // "connected"
    var installer: String?
}
