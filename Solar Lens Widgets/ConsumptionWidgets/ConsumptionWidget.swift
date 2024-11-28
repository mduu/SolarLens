//
//  ConsumptionWidget.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 28.11.2024.
//

import SwiftUI
import WidgetKit

struct ConsumptionWidget: Widget {
    // Create a unique string to identify the complication.
    let kind: String = "SolarLens-Consumption-Current"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConsumptionAppIntent.self,
            provider: ConsumptionWidgetProvider()
        ) { entry in
            ConsumptionWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Consumption")
        .description("Shows the current energy consumption.")
        .supportedFamilies([
            .accessoryCorner, .accessoryCircular, .accessoryInline, .accessoryInline
        ])
    }
}
