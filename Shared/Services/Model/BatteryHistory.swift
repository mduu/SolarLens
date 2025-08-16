internal import Foundation

struct BatteryHistory: Sendable, Identifiable {
    var id = UUID()
    let batterySensorId: String
    let items: [BatteryHistoryItem]
}

struct BatteryHistoryItem: Codable, Identifiable {
    var id = UUID()
    var date: Date

    /// Energy discharged from the battery during the interval (in Watt-hours).
    var energyDischargedWh: Double

    /// Energy charged into the battery during the interval (in Watt-hours).
    var energyChargedWh: Double

    /// Average power discharged from the battery during the interval (in Watts).
    var averagePowerDischargedW: Double

    /// Average power charged into the battery during the interval (in Watts).
    var averagePowerChargedW: Double

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

extension BatteryHistory {
    
    static func fakeHistory() -> [BatteryHistory] {
        var items: [BatteryHistoryItem] = []
        var date = Date.todayStartOfDay()

        let maxAbsoluteVariation: Double = 0.2

        var energyDischargedWh = 0.83
        var energyChargedWh = 0.005
        var averagePowerDischargedW = 1.0
        var averagePowerChargedW = 0.013

        repeat {
            let randomChange = Double.random(in: -maxAbsoluteVariation...maxAbsoluteVariation)
            energyDischargedWh = max(energyDischargedWh + randomChange, 0.0)
            energyChargedWh = max(energyChargedWh + randomChange, 0.0)
            averagePowerDischargedW = max(averagePowerDischargedW + randomChange, 0.0)
            averagePowerChargedW = max(averagePowerChargedW + randomChange, 0.0)
            
            items.append(
                BatteryHistoryItem(
                    date: date,
                    energyDischargedWh: energyDischargedWh,
                    energyChargedWh: energyChargedWh,
                    averagePowerDischargedW: averagePowerDischargedW,
                    averagePowerChargedW: averagePowerChargedW
                )
            )

            date = Calendar.current.date(byAdding: .minute, value: 5, to: date)!
        } while date < Date.todayEndOfDay()

        return [
            BatteryHistory(
                batterySensorId: "1234",
                items: items
            )
        ]
    }
    
}
