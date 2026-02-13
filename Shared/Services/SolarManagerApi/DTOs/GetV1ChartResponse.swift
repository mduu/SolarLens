struct GetV1ChartResponse : Codable {
    var lastUpdate: String
    var production: Double
    var consumption: Double
    var battery: BatteryStatusResponse?
    var arrows: [ArrowResponse]?
}

struct BatteryStatusResponse : Codable {
    var capacity: Double
    var batteryCharging: Double
    var batteryDischarging: Double
}

struct ArrowResponse: Codable {
    var direction: ArrowType
    var value: Double
}

enum ArrowType: String, Codable {
    case fromPVToGrid
    case fromGridToConsumer
    case fromPVToConsumer
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = ArrowType(rawValue: rawValue) ?? .unknown
    }
}
