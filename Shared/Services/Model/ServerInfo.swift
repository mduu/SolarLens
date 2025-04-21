import Foundation

struct ServerInfo {
    var status: String  // active
    var language: String?  // Deutsch
    var lastname: String?
    var firstname: String?
    var email: String
    var country: String?
    var license: String?  // "Solar Premium"
    var city: String?
    var street: String?
    var zip: String?
    var kWp: Double?
    var energyAssistantEnable: Bool
    var userId: String
    var registrationDate: Date?
    var deviceCount: Int
    var carCount: Int
    var smId: String
    var gatewayId: String
    var installationFinished: Bool = false
    var hardwareVersion: String
    var softwareVersion: String
    var signal: Bool  // "connected"
    var installer: String?
}

extension ServerInfo {
    static func fake() -> ServerInfo {
        ServerInfo(
            status: "active",
            email: "john.due@example.com",
            energyAssistantEnable: true,
            userId: "the-user-id",
            deviceCount: 4,
            carCount: 1,
            smId: "424242424242",
            gatewayId: "1234567890",
            hardwareVersion: "3.3.15",
            softwareVersion: "3.3.15",
            signal: true
        )
    }
}
