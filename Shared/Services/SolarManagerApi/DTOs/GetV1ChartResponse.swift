struct GetV1ChartResponse : Codable {
    var lastUpdate: String
    var production: Int
    var consumption: Int
    var battery: BatteryStatusResponse?
    var arrows: [ArrowResponse]?
}

struct BatteryStatusResponse : Codable {
    var capacity: Int
    var batteryCharging: Int
    var batteryDischarging: Int
}

struct ArrowResponse: Codable {
    var direction: ArrowType
    var value: Int
}

enum ArrowType: String, Codable {
    case fromPVToGrid
    case fromGridToConsumer
    case fromPVToConsumer
}
