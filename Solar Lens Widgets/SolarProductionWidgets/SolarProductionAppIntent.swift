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
    var todaySolarProduction: Double?
    var forecastToday: ForecastItem?
    var forecastTomorrow: ForecastItem?
    var forecastDayAfterTomorrow: ForecastItem?
    
    static func previewData() -> SolarProductionEntry {
        .init(
            date: Date(),
            currentProduction: 4540,
            maxProduction: 11000,
            todaySolarProduction: 6530,
            forecastToday: ForecastItem(min: 1, max: 4, expected: 3.2),
            forecastTomorrow: ForecastItem(min: 4, max: 5, expected: 6.98),
            forecastDayAfterTomorrow: ForecastItem(min: 5, max: 7, expected: 7.98)
        )
    }
}
