import Observation

@Observable
class ChargingStation: Identifiable {
    var id: String
    var name: String
    var chargingMode: ChargingMode
    var priority: Int  // lower number is higher Priority (ordering)
    var currentPower: Int  // Watt
    var signal: SensorConnectionStatus?

    init(
        id: String, name: String, chargingMode: ChargingMode, priority: Int,
        currentPower: Int, signal: SensorConnectionStatus? = nil
    ) {
        self.id = id
        self.name = name
        self.chargingMode = chargingMode
        self.priority = priority
        self.currentPower = currentPower
        self.signal = signal
    }
}
