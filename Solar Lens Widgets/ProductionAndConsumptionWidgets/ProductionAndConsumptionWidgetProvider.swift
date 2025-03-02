import Foundation
import WidgetKit

struct ProductionAndConsumptionWidgetProvider: AppIntentTimelineProvider {
    let widgetDataSource = SolarLensWidgetDataSource()

    func placeholder(in context: Context) -> ProductionAndConsumptionEntry {
        return .previewData()
    }

    func snapshot(
        for configuration: ProductionAndConsumptionAppIntent,
        in context: Context
    ) async -> ProductionAndConsumptionEntry {

        if context.isPreview {
            // A complication with generic data for preview
            return .previewData()
        }

        let data = try? await widgetDataSource.getOverviewData()

        print("SolarProduction Snapshot-Data \(String(describing: data))")

        return ProductionAndConsumptionEntry(
            date: Date(),
            currentProduction: data?.currentSolarProduction,
            maxProduction: data?.solarProductionMax,
            isStaleData: data?.isStaleData,
            toBattery: max(0, data?.currentBatteryChargeRate ?? 0),
            toGrid: data?.currentSolarToGrid,
            toHouse: (data?.currentSolarToHouse ?? 0)
                + (data?.currentGridToHouse ?? 0)
                + (min(data?.currentBatteryChargeRate ?? 0, 0) * -1),
            fromBattery: min(0, data?.currentBatteryChargeRate ?? 0) * -1,
            fromGrid: data?.currentGridToHouse,
            carCharging: data?.isAnyCarCharing
        )
    }

    func timeline(
        for configuration: ProductionAndConsumptionAppIntent,
        in context: Context
    ) async -> Timeline<ProductionAndConsumptionEntry> {
        var entries: [ProductionAndConsumptionEntry] = []

        if context.isPreview {
            // A complication with generic data for preview
            entries.append(.previewData())
        } else {
            let data = try? await widgetDataSource.getOverviewData()

            print("SolarProduction Timeline-Data \(String(describing: data))")

            entries.append(
                ProductionAndConsumptionEntry(
                    date: Date(),
                    currentProduction: data?.currentSolarProduction,
                    maxProduction: data?.solarProductionMax,
                    isStaleData: data?.isStaleData,
                    toBattery: max(0, data?.currentBatteryChargeRate ?? 0),
                    toGrid: data?.currentSolarToGrid,
                    toHouse: (data?.currentSolarToHouse ?? 0)
                        + (data?.currentGridToHouse ?? 0)
                        + (min(data?.currentBatteryChargeRate ?? 0, 0) * -1),
                    fromBattery: min(0, data?.currentBatteryChargeRate ?? 0) * -1,
                    fromGrid: data?.currentGridToHouse,
                    carCharging: data?.isAnyCarCharing
                )
            )
        }

        // Update every 5 minutes
        let currentDate = Date()
        let fiveMinutesLater = Calendar.current.date(
            byAdding: .minute, value: 5, to: currentDate)!
        return Timeline(
            entries: entries,
            policy: .after(fiveMinutesLater))
    }

    func recommendations() -> [AppIntentRecommendation<
        ProductionAndConsumptionAppIntent
    >] {
        // Create an array with all the preconfigured widgets to show.
        [
            AppIntentRecommendation(
                intent: ProductionAndConsumptionAppIntent(),
                description: "Current production and consumption")
        ]
    }

    //    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
    //        // Generate a list containing the contexts this widget is relevant in.
    //    }
}
