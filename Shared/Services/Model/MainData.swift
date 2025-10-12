import SwiftUI

@Observable
class MainData {
    var data: [MainDataItem] = []

    init(data: [MainDataItem]) {
        self.data = data
    }

    static func fake() -> MainData {
        let from = Date().addingTimeInterval(-8000)

        return MainData.init(
            data: [
                MainDataItem.init(
                    date: from,
                    consumptionWatts: 600,
                    productionWatts: 0,
                    batteryLevel: 44),
                MainDataItem.init(
                    date: from.addingTimeInterval(TimeInterval(300)),
                    consumptionWatts: 600,
                    productionWatts: 50,
                    batteryLevel: 45),
                MainDataItem.init(
                    date: from.addingTimeInterval(TimeInterval(600)),
                    consumptionWatts: 630,
                    productionWatts: 210,
                    batteryLevel: 49),
                MainDataItem.init(
                    date: from.addingTimeInterval(TimeInterval(900)),
                    consumptionWatts: 620,
                    productionWatts: 1200,
                    batteryLevel: 44),
                MainDataItem.init(
                    date: from.addingTimeInterval(TimeInterval(1200)),
                    consumptionWatts: 810,
                    productionWatts: 2140,
                    batteryLevel: 39),
                MainDataItem.init(
                    date: from.addingTimeInterval(TimeInterval(1500)),
                    consumptionWatts: 850,
                    productionWatts: 4329,
                    batteryLevel: 34),
                MainDataItem.init(
                    date: from.addingTimeInterval(TimeInterval(1800)),
                    consumptionWatts: 634,
                    productionWatts: 3732,
                    batteryLevel: 40),
                MainDataItem.init(
                    date: from.addingTimeInterval(TimeInterval(2100)),
                    consumptionWatts: 614,
                    productionWatts: 3560,
                    batteryLevel: 41),
                MainDataItem.init(
                    date: from.addingTimeInterval(TimeInterval(2400)),
                    consumptionWatts: 644,
                    productionWatts: 3120,
                    batteryLevel: 42),
                MainDataItem.init(
                    date: from.addingTimeInterval(TimeInterval(2700)),
                    consumptionWatts: 744,
                    productionWatts: 2938,
                    batteryLevel: 44),
                MainDataItem.init(
                    date: from.addingTimeInterval(TimeInterval(3000)),
                    consumptionWatts: 694,
                    productionWatts: 2648,
                    batteryLevel: 47),
                MainDataItem.init(
                    date: from.addingTimeInterval(TimeInterval(3300)),
                    consumptionWatts: 579,
                    productionWatts: 1902,
                    batteryLevel: 50),
                MainDataItem.init(
                    date: from.addingTimeInterval(TimeInterval(3600)),
                    consumptionWatts: 629,
                    productionWatts: 1538,
                    batteryLevel: 52),
            ]
        )
    }
}

struct MainDataItem: Codable, Identifiable {
    var id = UUID()
    var date: Date
    var consumptionWatts: Int
    var productionWatts: Int
    var batteryLevel: Int?

    init(date: Date, consumptionWatts: Int, productionWatts: Int, batteryLevel: Int?) {
        self.date = date
        self.consumptionWatts = consumptionWatts
        self.productionWatts = productionWatts
        self.batteryLevel = batteryLevel
    }
}
