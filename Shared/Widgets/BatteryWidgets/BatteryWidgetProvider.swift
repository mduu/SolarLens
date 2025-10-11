internal import Foundation
import WidgetKit

struct BatteryWidgetProvider: AppIntentTimelineProvider {
    let widgetDataSource = SolarLensWidgetDataSource()

    func placeholder(in context: Context) -> BatteryEntry {
        return .previewData()
    }

    func snapshot(
        for configuration: BatteryAppIntent, in context: Context
    ) async -> BatteryEntry {

        if context.isPreview {
            // A complication with generic data for preview
            return .previewData()
        }

        let data = try? await widgetDataSource.getOverviewData()
        
        print("Battery Snapshot-Data \(String(describing: data))")

        return BatteryEntry(
            date: Date(),
            currentBatteryLevel: data?.currentBatteryLevel,
            currentBatteryChargeRate: data?.currentBatteryChargeRate)
    }

    func timeline(
        for configuration: BatteryAppIntent, in context: Context
    ) async -> Timeline<BatteryEntry> {
        var entries: [BatteryEntry] = []

        if context.isPreview {
            // A complication with generic data for preview
            entries.append(.previewData())
        } else {
            let data = try? await widgetDataSource.getOverviewData()

            print("Battery Timeline-Data \(String(describing: data))")

            entries.append(
                BatteryEntry(
                    date: Date(),
                    currentBatteryLevel: data?.currentBatteryLevel,
                    currentBatteryChargeRate: data?.currentBatteryChargeRate))
        }

        // Update every 15 minutes
        let currentDate = Date()
        let fiftenMinutesLater = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        return Timeline(
            entries: entries,
            policy: .after(fiftenMinutesLater))
    }

    func recommendations() -> [AppIntentRecommendation<
        BatteryAppIntent
    >] {
        // Create an array with all the preconfigured widgets to show.
        [
            AppIntentRecommendation(
                intent: BatteryAppIntent(),
                description: "Current Battery Level")
        ]
    }

    //    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
    //        // Generate a list containing the contexts this widget is relevant in.
    //    }
}
