internal import Foundation
import AppIntents
import WidgetKit

enum ForecastDay: String, AppEnum {
    case auto
    case today
    case tomorrow
    case dayAfterTomorrow

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Forecast Day"
    }

    static var caseDisplayRepresentations: [ForecastDay: DisplayRepresentation] {
        [
            .auto: "Auto",
            .today: "Today",
            .tomorrow: "Tomorrow",
            .dayAfterTomorrow: "Day after tomorrow",
        ]
    }
}

struct ForecastAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Solar Forecast"
    static var description: IntentDescription = "Shows the solar production forecast."

    @Parameter(title: "Day", default: .auto)
    var day: ForecastDay

    static var parameterSummary: some ParameterSummary {
        Summary("Forecast for \(\.$day)")
    }
}

struct ForecastEntry: TimelineEntry {
    var date: Date
    var forecastToday: ForecastItem?
    var forecastTomorrow: ForecastItem?
    var forecastDayAfterTomorrow: ForecastItem?
    var selectedDay: ForecastDay = .auto
    var autoResolvedToTomorrow: Bool = false

    var displayedForecast: ForecastItem? {
        switch selectedDay {
        case .today:
            return forecastToday
        case .tomorrow:
            return forecastTomorrow
        case .dayAfterTomorrow:
            return forecastDayAfterTomorrow
        case .auto:
            return autoResolvedToTomorrow ? forecastTomorrow : forecastToday
        }
    }

    var dayLabel: String? {
        switch selectedDay {
        case .today:
            return nil
        case .tomorrow:
            return String(localized: "tmr")
        case .dayAfterTomorrow:
            return String(localized: "+2d")
        case .auto:
            return autoResolvedToTomorrow ? String(localized: "tmr") : nil
        }
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
            selectedDay: .auto,
            autoResolvedToTomorrow: false
        )
    }

    static func previewDataNight() -> ForecastEntry {
        .init(
            date: Date(),
            forecastToday: ForecastItem(min: 4, max: 8, expected: 5.6),
            forecastTomorrow: ForecastItem(min: 6, max: 12, expected: 9.2),
            forecastDayAfterTomorrow: ForecastItem(min: 3, max: 7, expected: 4.8),
            selectedDay: .auto,
            autoResolvedToTomorrow: true
        )
    }
}
