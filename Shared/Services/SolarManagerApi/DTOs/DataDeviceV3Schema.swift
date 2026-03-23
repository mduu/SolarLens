internal import Foundation

struct DataDeviceV3Schema: Decodable {
    var data: [DataDeviceV3SchemaData] = []
    var interval: Int = 0
}

struct DataDeviceV3SchemaData: Decodable {

    enum CodingKeys: String, CodingKey {
        case t, power, soc, iWh, eWh, temperature, activeDevice
    }

    /// Timestamp - ISO string or epoch milliseconds
    var t: String

    /// Device power in [watt]
    var power: Double = 0

    /// Battery state of charge in [%]
    var soc: Int? = nil

    /// Device energy consumed/imported in [watt-hours] over the specified interval
    var iWh: Double = 0

    /// Device energy produced/exported in [watt-hours] over the specified interval
    var eWh: Double = 0

    /// Temperature in [°C]
    var temperature: Double? = nil

    /// Device activity (1 on/charging, 0 off, -1 discharging)
    var activeDevice: Double? = nil

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // t can be a string (ISO date) or a number (epoch milliseconds)
        if let stringValue = try? container.decode(String.self, forKey: .t) {
            t = stringValue
        } else if let numberValue = try? container.decode(Double.self, forKey: .t) {
            let date = Date(timeIntervalSince1970: numberValue / 1000)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            t = formatter.string(from: date)
        } else {
            t = ""
        }

        power = (try? container.decode(Double.self, forKey: .power)) ?? 0
        soc = try? container.decode(Int.self, forKey: .soc)
        iWh = (try? container.decode(Double.self, forKey: .iWh)) ?? 0
        eWh = (try? container.decode(Double.self, forKey: .eWh)) ?? 0
        temperature = try? container.decode(Double.self, forKey: .temperature)
        activeDevice = try? container.decode(Double.self, forKey: .activeDevice)
    }
}
