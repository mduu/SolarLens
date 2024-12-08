import SwiftUI
import WidgetKit

struct ProductionAndConsumptionWidget: Widget {
    // Create a unique string to identify the complication.
    let kind: String = "SolarLens-ProductionAndConsumption"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ProductionAndConsumptionAppIntent.self,
            provider: ProductionAndConsumptionWidgetProvider()
        ) { entry in
            ProductionAndConsumptionWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Production & Consumption")
        .description("Shows the current production and consumptions.")
        .supportedFamilies([
            .accessoryCorner, .accessoryCircular
        ])
    }
}
