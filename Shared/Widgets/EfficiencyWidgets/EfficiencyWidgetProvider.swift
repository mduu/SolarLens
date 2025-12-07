internal import Foundation
import WidgetKit

struct EfficiencyWidgetProvider: AppIntentTimelineProvider {
    let widgetDataSource = SolarLensWidgetDataSource()

    func placeholder(in context: Context) -> EfficiencyEntry {
        return .previewData()
    }

    func snapshot(
        for configuration: EfficiencyAppIntent, in context: Context
    ) async -> EfficiencyEntry {

        if context.isPreview {
            // A complication with generic data for preview
            return .previewData()
        }

        let data = try? await widgetDataSource.getOverviewData()
        
        print("Efficiency Snapshot-Data \(String(describing: data))")

        return EfficiencyEntry(
            date: Date(),
            selfConsumption: data?.todaySelfConsumptionRate,
            autarky: data?.todayAutarchyDegree)
    }

    func timeline(
        for configuration: EfficiencyAppIntent, in context: Context
    ) async -> Timeline<EfficiencyEntry> {
        var entries: [EfficiencyEntry] = []

        if context.isPreview {
            // A complication with generic data for preview
            entries.append(.previewData())
        } else {
            let data = try? await widgetDataSource.getOverviewData()

            print("Efficiency Timeline-Data \(String(describing: data))")

            entries.append(
                EfficiencyEntry(
                    date: Date(),
                    selfConsumption: data?.todaySelfConsumptionRate,
                    autarky: data?.todayAutarchyDegree))
        }

        // Update every 15 minutes
        let currentDate = Date()
        let fiftenMinutesLater = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        return Timeline(
            entries: entries,
            policy: .after(fiftenMinutesLater))
    }

    func recommendations() -> [AppIntentRecommendation<
                               EfficiencyAppIntent
    >] {
        // Create an array with all the preconfigured widgets to show.
        [
            AppIntentRecommendation(
                intent: EfficiencyAppIntent(),
                description: "Efficiency")
        ]
    }

    //    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
    //        // Generate a list containing the contexts this widget is relevant in.
    //    }
}
