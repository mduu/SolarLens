import Foundation
import AppIntents
import WidgetKit

struct ProductionAndConsumptionAppIntent : WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Production & Consumption"
}

struct ProductionAndConsumptionEntry: TimelineEntry {
    var date: Date
    var currentProduction: Int?
    var maxProduction: Double?
    var isStaleData: Bool?
    var toBattery: Int?
    var toGrid: Int?
    var toHouse: Int?
    var fromBattery: Int?
    var fromGrid: Int?
    var carCharging: Bool?

    static func previewData(carCharging: Bool = true) -> ProductionAndConsumptionEntry {
        .init(
            date: Date(),
            currentProduction: 4100,
            maxProduction: 11000,
            isStaleData: false,
            toBattery: 1100,
            toGrid: 1000,
            toHouse: 2000,
            carCharging: carCharging
        )
    }
    
    static func previewDataBatteryOnly() -> ProductionAndConsumptionEntry {
        .init(
            date: Date(),
            currentProduction: 0,
            maxProduction: 11000,
            isStaleData: false,
            fromBattery: 1460
        )
    }
}
