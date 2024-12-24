import SwiftUI
import WidgetKit

struct SolarTimelineidget: Widget {
    // Create a unique string to identify the complication.
    let kind: String = "SolarLens-SolarProduction-History"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SolarTimelineAppIntent.self,
            provider: SolarTimelineWidgetProvider()
        ) { entry in
            SolarTimelineWidgetView(entry: entry)
        }
        .configurationDisplayName("Solar Production History")
        .description("Shows the solar production history.")
        .supportedFamilies([
            .accessoryRectangular
        ])
    }
}
