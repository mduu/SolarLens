internal import Foundation
import SwiftUI
import WidgetKit

struct ForecastWidgetProvider: AppIntentTimelineProvider {
    let widgetDataSource = SolarLensWidgetDataSource()

    func placeholder(in context: Context) -> ForecastEntry {
        return .previewData()
    }

    func snapshot(
        for configuration: ForecastAppIntent, in context: Context
    ) async -> ForecastEntry {
        if context.isPreview {
            return .previewData()
        }

        return await fetchEntry(day: configuration.day)
    }

    func timeline(
        for configuration: ForecastAppIntent, in context: Context
    ) async -> Timeline<ForecastEntry> {
        if context.isPreview {
            return Timeline(
                entries: [.previewData()],
                policy: .never
            )
        }

        let entry = await fetchEntry(day: configuration.day)

        let currentDate = Date()
        let fifteenMinutesLater = Calendar.current.date(
            byAdding: .minute, value: 15, to: currentDate)!
        return Timeline(
            entries: [entry],
            policy: .after(fifteenMinutesLater)
        )
    }

    func recommendations() -> [AppIntentRecommendation<ForecastAppIntent>] {
        let auto = ForecastAppIntent()
        auto.day = .auto

        let today = ForecastAppIntent()
        today.day = .today

        let tomorrow = ForecastAppIntent()
        tomorrow.day = .tomorrow

        let dayAfter = ForecastAppIntent()
        dayAfter.day = .dayAfterTomorrow

        return [
            AppIntentRecommendation(intent: auto, description: Text("Auto")),
            AppIntentRecommendation(intent: today, description: Text("Today")),
            AppIntentRecommendation(intent: tomorrow, description: Text("Tomorrow")),
            AppIntentRecommendation(intent: dayAfter, description: Text("Day after tomorrow")),
        ]
    }

    private func fetchEntry(day: ForecastDay) async -> ForecastEntry {
        let solarData = try? await widgetDataSource.getSolarProductionData()
        let overviewData = try? await widgetDataSource.getOverviewData()

        let hour = Calendar.current.component(.hour, from: Date())
        let currentProduction = overviewData?.currentSolarProduction ?? 0
        let autoResolvedToTomorrow =
            hour >= 20
            || hour < 6
            || (hour >= 18 && currentProduction == 0)

        return ForecastEntry(
            date: Date(),
            forecastToday: solarData?.forecastToday,
            forecastTomorrow: solarData?.forecastTomorrow,
            forecastDayAfterTomorrow: solarData?.forecastDayAfterTomorrow,
            selectedDay: day,
            autoResolvedToTomorrow: autoResolvedToTomorrow
        )
    }
}
