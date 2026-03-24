internal import Foundation
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

        return await fetchEntry()
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

        let entry = await fetchEntry()

        let currentDate = Date()
        let fifteenMinutesLater = Calendar.current.date(
            byAdding: .minute, value: 15, to: currentDate)!
        return Timeline(
            entries: [entry],
            policy: .after(fifteenMinutesLater)
        )
    }

    func recommendations() -> [AppIntentRecommendation<ForecastAppIntent>] {
        [
            AppIntentRecommendation(
                intent: ForecastAppIntent(),
                description: "Solar Forecast"
            )
        ]
    }

    private func fetchEntry() async -> ForecastEntry {
        let solarData = try? await widgetDataSource.getSolarProductionData()
        let overviewData = try? await widgetDataSource.getOverviewData()

        let hour = Calendar.current.component(.hour, from: Date())
        let currentProduction = overviewData?.currentSolarProduction ?? 0
        let isShowingTomorrow =
            hour >= 20
            || hour < 6
            || (hour >= 18 && currentProduction == 0)

        return ForecastEntry(
            date: Date(),
            forecastToday: solarData?.forecastToday,
            forecastTomorrow: solarData?.forecastTomorrow,
            forecastDayAfterTomorrow: solarData?.forecastDayAfterTomorrow,
            isShowingTomorrow: isShowingTomorrow
        )
    }
}
