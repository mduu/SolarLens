//
//  SolarProductionWidget.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 23.11.2024.
//

import SwiftUI
import WidgetKit

struct BatteryWidget: Widget {
    // Create a unique string to identify the complication.
    let kind: String = "SolarLens-Battery-Current"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: BatteryAppIntent.self,
            provider: BatteryWidgetProvider()
        ) { entry in
            BatteryWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Battery Level")
        .description("Shows the current battery level.")
        .supportedFamilies([
            .accessoryCorner, .accessoryCircular, .accessoryInline
        ])
    }
}
