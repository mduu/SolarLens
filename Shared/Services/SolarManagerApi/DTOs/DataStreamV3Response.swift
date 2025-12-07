struct DataStreamV3Response : Codable {
    /// Timestamp "2024-10-20T19:14:23.193Z"
    var t: String

    /// Consumption Watt
    var cW: Double

    /// Production Watt
    var pW: Double

    /// Watt
    var iW: Double

    /// List of device information
    var devices: [DataStreamV3Device]

    /// Battery state of charge in [%]
    var soc: Double = 0

    /// Battery charge power in [watt]
    var bcW: Double = 0

    /// Battery discharge power in [watt]
    var bdW: Double = 0

    // NOTE: Some more fields exists but we don't know that they mean so far
}

struct DataStreamV3Device : Codable {
    var _id: String

    var updatedAt: String?

    /// Device signal
    var signal: SensorConnectionStatus

    /// Device activity
    var activeDevice: Double?

    /// Power
    var power: Double?

    /// Battery state of charge in [%]
    var soc: Int?

    /// Temperature in [°C]
    var temperature: Double?

    /// Operation state for heatpumps
    var operationState: Double?

    /// Switch state for switches, smart plugs, car chargers
    var switchState: Double?

    /// Heating adjustment
    var heatingAdjustment: Double?

    /// Car: remaining Range in km
    var remainingRange: Double?
}

extension DataStreamV3Response {
    public func deviceById(_ id: String) -> DataStreamV3Device? {
        self.devices.first {
            $0._id == id
        }
    }
}
