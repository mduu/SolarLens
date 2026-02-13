enum SensorConnectionStatus : String, Codable {
    case connected = "connected"
    case notConnected = "not connected"
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = SensorConnectionStatus(rawValue: rawValue) ?? .unknown
    }
}
