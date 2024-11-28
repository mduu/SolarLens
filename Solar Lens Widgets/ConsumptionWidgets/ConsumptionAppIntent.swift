//
//  SolarProductionAppIntent.swift
//  Solar Lens Watch App
//
//  Created by Marc Dürst on 22.11.2024.
//

import Foundation
import AppIntents
import WidgetKit

struct ConsumptionAppIntent : WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Consumption"
}

struct ConsumptionEntry: TimelineEntry {
    var date: Date
    
    var currentConsumption: Int?
    var carCharging: Bool?
    
    static func previewData() -> ConsumptionEntry {
        .init(date: Date(), currentConsumption: 890, carCharging: true)
    }
}
