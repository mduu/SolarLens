import SwiftUI

@Observable
class ConsumptionData {
    var from: Date?
    var to: Date?
    var interval: Int = 300
    var data: [ConsumptionItem] = []

    init(from: Date?, to: Date?, interval: Int, data: [ConsumptionItem]) {
        self.from = from
        self.to = to
        self.interval = interval
        self.data = data
    }

    static func fake() -> ConsumptionData {
        let from = Date().addingTimeInterval(-8000)
        let to = Date()

        return ConsumptionData.init(
            from: from,
            to: to,
            interval: 300,
            data: [
                ConsumptionItem.init(
                    date: from,
                    consumptionWatts: 600,
                    productionWatts: 0),
                ConsumptionItem.init(
                    date: from.addingTimeInterval(TimeInterval(300)),
                    consumptionWatts: 600,
                    productionWatts: 50),
                ConsumptionItem.init(
                    date: from.addingTimeInterval(TimeInterval(600)),
                    consumptionWatts: 630,
                    productionWatts: 210),
                ConsumptionItem.init(
                    date: from.addingTimeInterval(TimeInterval(900)),
                    consumptionWatts: 620,
                    productionWatts: 1200),
                ConsumptionItem.init(
                    date: from.addingTimeInterval(TimeInterval(1200)),
                    consumptionWatts: 810,
                    productionWatts: 2140),
                ConsumptionItem.init(
                    date: from.addingTimeInterval(TimeInterval(1500)),
                    consumptionWatts: 850,
                    productionWatts: 4329),
                ConsumptionItem.init(
                    date: from.addingTimeInterval(TimeInterval(1800)),
                    consumptionWatts: 634,
                    productionWatts: 3732),
                ConsumptionItem.init(
                    date: from.addingTimeInterval(TimeInterval(2100)),
                    consumptionWatts: 614,
                    productionWatts: 3560),
                ConsumptionItem.init(
                    date: from.addingTimeInterval(TimeInterval(2400)),
                    consumptionWatts: 644,
                    productionWatts: 3120),
                ConsumptionItem.init(
                    date: from.addingTimeInterval(TimeInterval(2700)),
                    consumptionWatts: 744,
                    productionWatts: 2938),
                ConsumptionItem.init(
                    date: from.addingTimeInterval(TimeInterval(3000)),
                    consumptionWatts: 694,
                    productionWatts: 2648),
                ConsumptionItem.init(
                    date: from.addingTimeInterval(TimeInterval(3300)),
                    consumptionWatts: 579,
                    productionWatts: 1902),
                ConsumptionItem.init(
                    date: from.addingTimeInterval(TimeInterval(3600)),
                    consumptionWatts: 629,
                    productionWatts: 1538),
            ]
        )
    }
}

struct ConsumptionItem: Codable, Identifiable {
    var id = UUID()
    var date: Date
    var consumptionWatts: Double
    var productionWatts: Double

    init(date: Date, consumptionWatts: Double, productionWatts: Double) {
        self.date = date
        self.consumptionWatts = consumptionWatts
        self.productionWatts = productionWatts
    }
}
