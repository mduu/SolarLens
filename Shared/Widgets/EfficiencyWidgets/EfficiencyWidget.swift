import SwiftUI
import WidgetKit

struct EfficiencyWidget: Widget {
    // Create a unique string to identify the complication.
    let kind: String = "SolarLens-Efficiency"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: EfficiencyAppIntent.self,
            provider: EfficiencyWidgetProvider()
        ) { entry in
            EfficiencyWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Efficiency")
        .description("Shows the rings of today efficiency.")
        .supportedFamilies(getSupportedFamilies())
    }
    
    private func getSupportedFamilies() -> [WidgetFamily] {
        var families: [WidgetFamily] = [
            .accessoryCircular,
            .accessoryInline
        ]
        #if os(watchOS)
        #else
        families.append(.systemSmall)
        families.append(.systemMedium)
        #endif
        return families
    }
}
