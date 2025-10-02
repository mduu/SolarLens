internal import Foundation
import WidgetKit

struct SolarTimelineWidgetProvider: AppIntentTimelineProvider {
    let widgetDataSource = SolarLensWidgetDataSource()

    func placeholder(in context: Context) -> SolarTimelineEntry {
        return .previewData()
    }

    func snapshot(
        for configuration: SolarTimelineAppIntent, in context: Context
    ) async -> SolarTimelineEntry {

        if context.isPreview {
            // A complication with generic data for preview
            return .previewData()
        }

        let data = try? await widgetDataSource.getOverviewData()
        let solarData = try? await widgetDataSource.getSolarProductionData()
        let historyData = try? await widgetDataSource.getComsumptionData()

        print("SolarTimeline Snapshot-Data \(String(describing: data))")

        return SolarTimelineEntry(
            date: Date(),
            history: historyData,
            currentProduction: data?.currentSolarProduction,
            maxProduction: data?.solarProductionMax,
            todaySolarProduction: solarData?.todaySolarProduction
        )
    }

    func timeline(
        for configuration: SolarTimelineAppIntent, in context: Context
    ) async -> Timeline<SolarTimelineEntry> {
        var entries: [SolarTimelineEntry] = []

        if context.isPreview {
            // A complication with generic data for preview
            entries.append(.previewData())
        } else {
            let data = try? await widgetDataSource.getOverviewData()
            let solarData = try? await widgetDataSource.getSolarProductionData()
            let historyData = try? await widgetDataSource.getComsumptionData()

            print("SolarProduction Timeline-Data \(String(describing: data))")

            entries.append(
                SolarTimelineEntry(
                    date: Date(),
                    history: historyData,
                    currentProduction: data?.currentSolarProduction,
                    maxProduction: data?.solarProductionMax,
                    todaySolarProduction: solarData?.todaySolarProduction
                )
            )
        }

        // Update every 5 minutes
        let currentDate = Date()
        let tenMinutesLater = Calendar.current.date(
            byAdding: .minute, value: 10, to: currentDate)!
        return Timeline(
            entries: entries,
            policy: .after(tenMinutesLater))
    }

    func recommendations() -> [AppIntentRecommendation<
        SolarTimelineAppIntent
    >] {
        // Create an array with all the preconfigured widgets to show.
        [
            AppIntentRecommendation(
                intent: SolarTimelineAppIntent(),
                description: "Solar Production History")
        ]
    }

    //    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
    //        // Generate a list containing the contexts this widget is relevant in.
    //    }
}
