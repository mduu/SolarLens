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
        .supportedFamilies([
            .accessoryRectangular
        ])
    }
}
