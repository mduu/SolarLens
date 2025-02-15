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
        .supportedFamilies(getSupportedFamilies())
    }
    
    private func getSupportedFamilies() -> [WidgetFamily] {
        var families: [WidgetFamily] = [
            .accessoryCircular,
            .accessoryInline
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
