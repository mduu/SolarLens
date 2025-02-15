import SwiftUI
import WidgetKit

struct ConsumptionWidget: Widget {
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
        .supportedFamilies(getSupportedFamilies())
    }
    
    private func getSupportedFamilies() -> [WidgetFamily] {
        var families: [WidgetFamily] = [
            .accessoryCircular,
            .accessoryInline,
            .accessoryRectangular
        ]
        #if os(watchOS)
        families.append(.accessoryCorner)
        #else
        families.append(.systemMedium)
        families.append(.systemSmall)
        #endif
        return families
    }
}
