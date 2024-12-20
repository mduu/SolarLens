import SwiftUI
import WidgetKit

struct SolarProductionWidget: Widget {
    // Create a unique string to identify the complication.
    let kind: String = "SolarLens-SolarProduction-Current"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SolarProductionAppIntent.self,
            provider: SolarProductionWidgetProvider()
        ) { entry in
            SolarProductionWidgetView(entry: entry)
        }
        .configurationDisplayName("Solar Production")
        .description("Shows the current solar production.")
        .supportedFamilies([
            .accessoryCorner, .accessoryCircular, .accessoryInline, .accessoryRectangular
        ])
    }
}
