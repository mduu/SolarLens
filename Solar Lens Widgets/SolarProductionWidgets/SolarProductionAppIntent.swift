//
//  SolarProductionAppIntent.swift
//  Solar Lens Watch App
//
//  Created by Marc Dürst on 22.11.2024.
//

import Foundation
import AppIntents
import WidgetKit

struct SolarProductionAppIntent : WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Solar Production"
}

struct SolarProductionEntry: TimelineEntry {
    var date: Date
    var currentProduction: Int?
    var maxProduction: Double?
    
    static func previewData() -> SolarProductionEntry {
        .init(date: Date(), currentProduction: 4540, maxProduction: 11000)
    }
}
