import SwiftUI
import WidgetKit

struct TodayTimelineidget: Widget {
    // Create a unique string to identify the complication.
    let kind: String = "SolarLens-Today-History"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: TodayTimelineAppIntent.self,
            provider: TodayTimelineWidgetProvider()
        ) { entry in
            TodayTimelineWidgetView(entry: entry)
        }
        .configurationDisplayName("Today History")
        .description("Shows todays production and consumption as chart.")
        .supportedFamilies(getSupportedFamilies())
    }

    private func getSupportedFamilies() -> [WidgetFamily] {
        var families: [WidgetFamily] = []
        #if os(iOS)
            families.append(.systemMedium)
            families.append(.systemSmall)
        #endif
        
        #if os(watchOS)
        families.append(.accessoryRectangular)
        #endif
        
        return families
    }
}
