import Foundation

struct BatteryHistory: Sendable {
    let batterySensorId: String
    let items: [BatteryHistoryItem]
}

struct BatteryHistoryItem: Sendable, Identifiable {
    let id = UUID()
    let date: Date

    /// Energy discharged from the battery during the interval (in Watt-hours).
    let energyDischargedWh: Double

    /// Energy charged into the battery during the interval (in Watt-hours).
    let energyChargedWh: Double

    /// Average power discharged from the battery during the interval (in Watts).
    let averagePowerDischargedW: Double

    /// Average power charged into the battery during the interval (in Watts).
    let averagePowerChargedW: Double

    init(
        date: Date,
        energyDischargedWh: Double,
        energyChargedWh: Double,
        averagePowerDischargedW: Double,
        averagePowerChargedW: Double
    ) {
        self.date = date
        self.energyDischargedWh = energyDischargedWh
        self.energyChargedWh = energyChargedWh
        self.averagePowerDischargedW = averagePowerDischargedW
        self.averagePowerChargedW = averagePowerChargedW
    }
}
