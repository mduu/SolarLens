//
//  SolarProductionAppIntent.swift
//  Solar Lens Watch App
//
//  Created by Marc Dürst on 22.11.2024.
//

internal import Foundation
import AppIntents
import WidgetKit

struct SolarTimelineAppIntent : WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Solar Production Timline"
}

struct SolarTimelineEntry: TimelineEntry {
    var date: Date
    var history: ConsumptionData?
    var currentProduction: Int?
    var maxProduction: Double?
    var todaySolarProduction: Double?
    
    static func previewData() -> SolarTimelineEntry {
        .init(
            date: Date(),
            history: ConsumptionData.fake(),
            currentProduction: 4540,
            maxProduction: 11000,
            todaySolarProduction: 6530
        )
    }
}
