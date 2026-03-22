internal import Foundation

struct DataMainV3Schema: Codable {

    var data: [DataMainV3SchemaData] = []
    var interval: Int = 0

}

struct DataMainV3SchemaData: Codable {

    /// Timestamp - ISO string or epoch milliseconds
    var t: String

    /// Consumption power in [watt]
    var cW: Double = 0

    /// Production power in [watt]
    var pW: Double = 0

    /// Consumption energy in [watt-hour] over the specified interval
    var cWh: Double = 0

    /// Production energy in [watt-hour] over the specified interval
    var pWh: Double = 0

    /// Battery state of charge in [%]
    var soc: Double? = nil

    /// Battery charging power in [watt]
    var bcW: Double = 0

    /// Battery discharge power in [watt]
    var bdW: Double = 0

    /// Battery charging energy in [watt-hour] over the specified interval
    var bcWh: Double = 0

    /// Battery discharging energy in [watt-hour] over the specified interval
    var bdWh: Double = 0

    /// Import energy [watt-hour] over the specified interval
    var iWh: Double = 0

    /// Export energy [watt-hour] over the specified interval
    var eWh: Double = 0

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // t can be a string (ISO date) or a number (epoch milliseconds)
        if let stringValue = try? container.decode(String.self, forKey: .t) {
            t = stringValue
        } else if let numberValue = try? container.decode(Double.self, forKey: .t) {
            // Convert epoch milliseconds to ISO 8601 string
            let date = Date(timeIntervalSince1970: numberValue / 1000)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            t = formatter.string(from: date)
        } else {
            t = ""
        }

        cW = (try? container.decode(Double.self, forKey: .cW)) ?? 0
        pW = (try? container.decode(Double.self, forKey: .pW)) ?? 0
        cWh = (try? container.decode(Double.self, forKey: .cWh)) ?? 0
        pWh = (try? container.decode(Double.self, forKey: .pWh)) ?? 0
        soc = try? container.decode(Double.self, forKey: .soc)
        bcW = (try? container.decode(Double.self, forKey: .bcW)) ?? 0
        bdW = (try? container.decode(Double.self, forKey: .bdW)) ?? 0
        bcWh = (try? container.decode(Double.self, forKey: .bcWh)) ?? 0
        bdWh = (try? container.decode(Double.self, forKey: .bdWh)) ?? 0
        iWh = (try? container.decode(Double.self, forKey: .iWh)) ?? 0
        eWh = (try? container.decode(Double.self, forKey: .eWh)) ?? 0
    }
}
