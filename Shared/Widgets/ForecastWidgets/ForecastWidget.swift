import SwiftUI
import WidgetKit

struct ForecastWidget: Widget {
    let kind: String = "SolarLens-Forecast-Today"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ForecastAppIntent.self,
            provider: ForecastWidgetProvider()
        ) { entry in
            ForecastWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Solar Forecast")
        .description("Shows today's solar production forecast.")
        .supportedFamilies(getSupportedFamilies())
    }

    private func getSupportedFamilies() -> [WidgetFamily] {
        var families: [WidgetFamily] = [
            .accessoryCircular,
            .accessoryInline,
        ]
        #if os(watchOS)
            families.append(.accessoryCorner)
        #endif
        return families
    }
}
