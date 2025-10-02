internal import Foundation

class V1User: Codable {
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
    var registration_date: String?  // "2024-09-20T08:15:54.138Z"
    var device_count: Int
    var car_count: Int
    var sm_id: String
    var gateway_id: String
    var installation_finished: Bool = false
    var hardware_version: String
    var firmware_version: String
    var signal: String  // "connected"
    var installer: String?

    var registrationDate: Date {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]

        return
            isoFormatter.date(from: registration_date ?? "")
            ?? Calendar.current.date(from: DateComponents(year: 2020, month: 1, day: 1))!
    }
}
