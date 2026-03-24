internal import Foundation
import AppIntents
import WidgetKit

struct ForecastAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Solar Forecast"
}

struct ForecastEntry: TimelineEntry {
    var date: Date
    var forecastToday: ForecastItem?
    var forecastTomorrow: ForecastItem?
    var forecastDayAfterTomorrow: ForecastItem?
    var isShowingTomorrow: Bool = false

    var displayedForecast: ForecastItem? {
        isShowingTomorrow ? forecastTomorrow : forecastToday
    }

    var gaugeMax: Double {
        let maxValues: [Double] = [
            forecastToday?.max ?? 0,
            forecastTomorrow?.max ?? 0,
            forecastDayAfterTomorrow?.max ?? 0,
        ]
        return Swift.max(maxValues.max() ?? 1, 1)
    }

    static func previewData() -> ForecastEntry {
        .init(
            date: Date(),
            forecastToday: ForecastItem(min: 4, max: 8, expected: 5.6),
            forecastTomorrow: ForecastItem(min: 6, max: 12, expected: 9.2),
            forecastDayAfterTomorrow: ForecastItem(min: 3, max: 7, expected: 4.8),
            isShowingTomorrow: false
        )
    }

    static func previewDataNight() -> ForecastEntry {
        .init(
            date: Date(),
            forecastToday: ForecastItem(min: 4, max: 8, expected: 5.6),
            forecastTomorrow: ForecastItem(min: 6, max: 12, expected: 9.2),
            forecastDayAfterTomorrow: ForecastItem(min: 3, max: 7, expected: 4.8),
            isShowingTomorrow: true
        )
    }
}
