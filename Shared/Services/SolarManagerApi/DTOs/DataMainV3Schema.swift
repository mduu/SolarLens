struct DataMainV3Schema: Codable {

    var data: [DataMainV3SchemaData] = []

}

struct DataMainV3SchemaData: Codable {

    /// Timestamp - Example: 2022-06-01T00:00:00.000Z
    var t: String

    /// Consumption power in [watt]
    var cW: Int = 0

    /// Production power in [watt]
    var pW: Int = 0

    /// Consumption energy in [watt-hour] over the specified interval
    var cWh: Double = 0

    /// Production energy in [watt-hour] over the specified interval
    var pWh: Double = 0

    /// Battery state of charge in [%]
    var soc: Int = 0

    /// Battery charging power in [watt]
    var bcW: Int = 0

    /// Battery discharge power in [watt]
    var bdW: Int = 0

    /// Battery charging energy in [watt-hour] over the specified interval
    var bcWh: Double = 0

    /// Battery discharging energy in [watt-hour] over the specified interval
    var bdWh: Double = 0

    /// Import energy [watt-hour] over the specified interval
    var iWh: Double = 0

    /// Export energy [watt-hour] over the specified interval
    var eWh: Double = 0
}
