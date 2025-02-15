import AppIntents
import Foundation
import WidgetKit

struct ConsumptionAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Consumption"
}

struct ConsumptionEntry: TimelineEntry {
    var date: Date

    var currentConsumption: Int?
    var carCharging: Bool?
    var consumptionFromSolar: Int?
    var consumptionFromBattery: Int?
    var consumptionFromGrid: Int?
    var isStaleData: Bool?

    static func previewData() -> ConsumptionEntry {
        .init(
            date: Date(),
            currentConsumption: 5200,
            carCharging: false,
            consumptionFromSolar: 400,
            consumptionFromBattery: 800,
            consumptionFromGrid: 4000,
            isStaleData: false)
    }
}
