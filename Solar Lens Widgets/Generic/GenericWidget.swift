//
//  ConsumptionWidget.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 28.11.2024.
//

import SwiftUI
import WidgetKit

struct GenericWidget: Widget {
    let kind: String = "SolarLens-Generic"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: GenericAppIntent.self,
            provider: GenericWidgetProvider()
        ) { entry in
            GenericWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("App icon")
        .description("Shows the Solar Lens app icon.")
        .supportedFamilies([
            .accessoryCorner, .accessoryCircular
        ])
    }
}
