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
                    consumptionOverTimeWatthours: 4309.23,
                    productionWatts: 0,
                    productionOverTimeWatthours: 12.2,
                    batteryLevel: 44,
                    importedOverTimeWhatthours: 2344.3,
                    exportedOverTimeWhatthours: 11.22
                ),
                MainDataItem.init(
                    date: from.addingTimeInterval(TimeInterval(300)),
                    consumptionWatts: 600,
                    consumptionOverTimeWatthours: 4124.2,
                    productionWatts: 50,
                    productionOverTimeWatthours: 1234.2,
                    batteryLevel: 45,
                    importedOverTimeWhatthours: 123.1,
                    exportedOverTimeWhatthours: 111.24
                ),
                MainDataItem.init(
                    date: from.addingTimeInterval(TimeInterval(600)),
                    consumptionWatts: 630,
                    consumptionOverTimeWatthours: 5434.3,
                    productionWatts: 210,
                    productionOverTimeWatthours: 2423.3,
                    batteryLevel: 49,
                    importedOverTimeWhatthours: 333.2,
                    exportedOverTimeWhatthours: 222.1
                ),
                MainDataItem.init(
                    date: from.addingTimeInterval(TimeInterval(900)),
                    consumptionWatts: 620,
                    consumptionOverTimeWatthours: 2312.4,
                    productionWatts: 1200,
                    productionOverTimeWatthours: 3234.3,
                    batteryLevel: 44,
                    importedOverTimeWhatthours: 222.2,
                    exportedOverTimeWhatthours: 1231.2
                ),
                MainDataItem.init(
                    date: from.addingTimeInterval(TimeInterval(1200)),
                    consumptionWatts: 810,
                    consumptionOverTimeWatthours: 1231.2,
                    productionWatts: 2140,
                    productionOverTimeWatthours: 1211.2,
                    batteryLevel: 39,
                    importedOverTimeWhatthours: 123.2,
                    exportedOverTimeWhatthours: 0
                ),
                MainDataItem.init(
                    date: from.addingTimeInterval(TimeInterval(1500)),
                    consumptionWatts: 850,
                    consumptionOverTimeWatthours: 3242.7,
                    productionWatts: 4329,
                    productionOverTimeWatthours: 9030.3,
                    batteryLevel: 34,
                    importedOverTimeWhatthours: 0,
                    exportedOverTimeWhatthours: 0
                ),
                MainDataItem.init(
                    date: from.addingTimeInterval(TimeInterval(1800)),
                    consumptionWatts: 634,
                    consumptionOverTimeWatthours: 3239.2,
                    productionWatts: 3732,
                    productionOverTimeWatthours: 10239,
                    batteryLevel: 40,
                    importedOverTimeWhatthours: 0,
                    exportedOverTimeWhatthours: 0
                ),
                MainDataItem.init(
                    date: from.addingTimeInterval(TimeInterval(2100)),
                    consumptionWatts: 614,
                    consumptionOverTimeWatthours: 3420.3,
                    productionWatts: 3560,
                    productionOverTimeWatthours: 10239,
                    batteryLevel: 41,
                    importedOverTimeWhatthours: 0,
                    exportedOverTimeWhatthours: 0
                ),
                MainDataItem.init(
                    date: from.addingTimeInterval(TimeInterval(2400)),
                    consumptionWatts: 644,
                    consumptionOverTimeWatthours: 3423.3,
                    productionWatts: 3120,
                    productionOverTimeWatthours: 10231.3,
                    batteryLevel: 42,
                    importedOverTimeWhatthours: 0,
                    exportedOverTimeWhatthours: 0
                ),
                MainDataItem.init(
                    date: from.addingTimeInterval(TimeInterval(2700)),
                    consumptionWatts: 744,
                    consumptionOverTimeWatthours: 4432.3,
                    productionWatts: 2938,
                    productionOverTimeWatthours: 6090.2,
                    batteryLevel: 44,
                    importedOverTimeWhatthours: 0,
                    exportedOverTimeWhatthours: 0
                ),
                MainDataItem.init(
                    date: from.addingTimeInterval(TimeInterval(3000)),
                    consumptionWatts: 694,
                    consumptionOverTimeWatthours: 4500,
                    productionWatts: 2648,
                    productionOverTimeWatthours: 7030,
                    batteryLevel: 47,
                    importedOverTimeWhatthours: 0,
                    exportedOverTimeWhatthours: 0
                ),
                MainDataItem.init(
                    date: from.addingTimeInterval(TimeInterval(3300)),
                    consumptionWatts: 579,
                    consumptionOverTimeWatthours: 3209.3,
                    productionWatts: 1902,
                    productionOverTimeWatthours: 4390,
                    batteryLevel: 50,
                    importedOverTimeWhatthours: 0,
                    exportedOverTimeWhatthours: 0
                ),
                MainDataItem.init(
                    date: from.addingTimeInterval(TimeInterval(3600)),
                    consumptionWatts: 629,
                    consumptionOverTimeWatthours: 3490,
                    productionWatts: 1538,
                    productionOverTimeWatthours: 6543.3,
                    batteryLevel: 52,
                    importedOverTimeWhatthours: 0,
                    exportedOverTimeWhatthours: 213.4
                ),
            ]
        )
    }
}

struct MainDataItem: Codable, Identifiable {
    var id = UUID()
    var date: Date
    var consumptionWatts: Double
    var consumptionOverTimeWatthours: Double
    var productionWatts: Double
    var productionOverTimeWatthours: Double
    var batteryLevel: Int?
    var importedOverTimeWhatthours: Double
    var exportedOverTimeWhatthours: Double

    init(
        date: Date,
        consumptionWatts: Double,
        consumptionOverTimeWatthours: Double,
        productionWatts: Double,
        productionOverTimeWatthours: Double,
        batteryLevel: Int?,
        importedOverTimeWhatthours: Double,
        exportedOverTimeWhatthours: Double
    ) {
        self.date = date
        self.consumptionWatts = consumptionWatts
        self.consumptionOverTimeWatthours = consumptionOverTimeWatthours
        self.productionWatts = productionWatts
        self.productionOverTimeWatthours = productionOverTimeWatthours
        self.batteryLevel = batteryLevel
        self.importedOverTimeWhatthours = importedOverTimeWhatthours
        self.exportedOverTimeWhatthours = exportedOverTimeWhatthours
    }
}
