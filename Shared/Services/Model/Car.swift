import Observation

@Observable
class Car: Identifiable {
    var id: String
    var name: String
    var priority: Int
    var batteryPercent: Double?
    var batteryCapacity: Double?
    var signal: SensorConnectionStatus
    var currentPowerInWatts: Int = 0
    var hasError: Bool = false

    init(
        id: String,
        name: String,
        priority: Int,
        batteryPercent: Double?,
        batteryCapacity: Double?,
        signal: SensorConnectionStatus,
        currentPowerInWatts: Int,
        hasError: Bool
    ) {
        self.id = id
        self.name = name
        self.priority = priority
        self.batteryPercent = batteryPercent
        self.batteryCapacity = batteryCapacity
        self.signal = signal
        self.currentPowerInWatts = currentPowerInWatts
        self.hasError = hasError
    }
}
