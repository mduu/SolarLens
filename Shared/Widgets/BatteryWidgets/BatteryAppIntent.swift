//
//  BatteryAppIntent.swift
//  Solar Lens Watch App
//
//  Created by Marc Dürst on 02.12.2024.
//

import Foundation
import AppIntents
import WidgetKit

struct BatteryAppIntent : WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Solar Production"
}

struct BatteryEntry: TimelineEntry {
    var date: Date
    var currentBatteryLevel: Int?
    var currentBatteryChargeRate: Int?
    
    static func previewData() -> BatteryEntry {
        .init(
            date: Date(),
            currentBatteryLevel: 78,
            currentBatteryChargeRate: 3400
        )
    }
}

