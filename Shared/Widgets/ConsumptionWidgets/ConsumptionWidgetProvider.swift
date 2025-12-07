internal import Foundation
import WidgetKit

struct ConsumptionWidgetProvider: AppIntentTimelineProvider {
    let widgetDataSource = SolarLensWidgetDataSource()

    func placeholder(in context: Context) -> ConsumptionEntry {
        return .previewData()
    }

    func snapshot(
        for configuration: ConsumptionAppIntent, in context: Context
    ) async -> ConsumptionEntry {

        if context.isPreview {
            // A complication with generic data for preview
            return .previewData()
        }

        let data = try? await widgetDataSource.getOverviewData()
        
        print("Snapshot-Data \(data?.currentOverallConsumption ?? 0)")

        return ConsumptionEntry(
            date: Date(),
            currentConsumption: data?.currentOverallConsumption,
            carCharging: data?.isAnyCarCharing,
            consumptionFromSolar: data?.currentSolarToHouse,
            consumptionFromBattery: data?.currentBatteryChargeRate ?? 0 * -1,
            consumptionFromGrid: data?.currentGridToHouse,
            isStaleData: data?.isStaleData)
    }

    func timeline(
        for configuration: ConsumptionAppIntent, in context: Context
    ) async -> Timeline<ConsumptionEntry> {
        var entries: [ConsumptionEntry] = []

        if context.isPreview {
            // A complication with generic data for preview
            entries.append(.previewData())
        } else {
            let data = try? await widgetDataSource.getOverviewData()

            print("Timeline-Data \(data?.currentOverallConsumption ?? -1)")

            entries.append(
                ConsumptionEntry(
                    date: Date(),
                    currentConsumption: data?.currentOverallConsumption,
                    carCharging: data?.isAnyCarCharing,
                    consumptionFromSolar: data?.currentSolarToHouse,
                    consumptionFromBattery: Int(data?.currentBatteryChargeRate ?? 0) * -1,
                    consumptionFromGrid: data?.currentGridToHouse,
                    isStaleData: data?.isStaleData))
        }

        // Update every 5 minutes
        let currentDate = Date()
        let fiveMinutesLater = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!
        return Timeline(
            entries: entries,
            policy: .after(fiveMinutesLater))
    }

    func recommendations() -> [AppIntentRecommendation<
        ConsumptionAppIntent
    >] {
        // Create an array with all the preconfigured widgets to show.
        [
            AppIntentRecommendation(
                intent: ConsumptionAppIntent(),
                description: "Current consumption")
        ]
    }

    //    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
    //        // Generate a list containing the contexts this widget is relevant in.
    //    }
}
