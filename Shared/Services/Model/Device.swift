import Observation

@Observable
class Device: Identifiable {
    var id: String
    var deviceType: DeviceType = .other
    var name: String = ""
    var priority: Int
    var currentPowerInWatts: Int = 0
    var color: String?
    var signal: SensorConnectionStatus
    var hasError: Bool = false
    var batteryInfo: BatteryInfo? = nil

    init(
        id: String,
        deviceType: DeviceType,
        name: String = "",
        priority: Int,
        currentPowerInWatts: Int = 0,
        color: String? = nil,
        signal: SensorConnectionStatus = .connected,
        hasError: Bool = false,
        batteryInfo: BatteryInfo? = nil
    ) {
        self.id = id
        self.deviceType = deviceType
        self.name = name
        self.priority = priority
        self.currentPowerInWatts = currentPowerInWatts
        self.color = color
        self.signal = signal
        self.hasError = hasError
        self.batteryInfo = batteryInfo
    }

    func hasPower() -> Bool {
        return currentPowerInWatts > 10 || currentPowerInWatts < -10
    }

    func isConsumingDevice() -> Bool {
        return deviceType != .battery
    }

}

extension Device {

    static func mapStringToDeviceType(stringValue: String?) -> DeviceType {
        guard let value = stringValue?.lowercased() else {
            return .other
        }

        switch value {
        case "energy measurement":
            return .energyMeasurement
        case "battery":
            return .battery
        case "car charging":
            return .carCharging
        default:
            return .other
        }
    }

    static func fakeBattery(
        id: String = "1234",
        name: String = "Bat 1",
        priority: Int = 0,
        currentPowerInWatts: Int = 4242,
    ) -> Device {
        .init(
            id: "123",
            deviceType: .battery,
            name: name,
            priority: 0,
            currentPowerInWatts: currentPowerInWatts,
            batteryInfo: BatteryInfo.fake()
        )
    }
}

public enum DeviceType {
    case carCharging
    case battery
    case energyMeasurement
    case other
}
