//
//  SolarProductionProvider.swift
//  Solar Lens Watch App
//
//  Created by Marc Dürst on 22.11.2024.
//

import Foundation
import WidgetKit

struct SolarProductionWidgetProvider: AppIntentTimelineProvider {
    let solarManager = SolarManager()

    func placeholder(in context: Context) -> SolarProductionEntry {
        return .previewData()
    }

    func snapshot(
        for configuration: SolarProductionAppIntent, in context: Context
    ) async -> SolarProductionEntry {

        if context.isPreview {
            // A complication with generic data for preview
            return .previewData()
        }

        let data = try? await solarManager.fetchOverviewData(
            lastOverviewData: nil)
        
        print("Snapshot-Data \(data?.currentSolarProduction ?? 0)")

        return SolarProductionEntry(
            date: Date(),
            currentProduction: data?.currentSolarProduction,
            maxProduction: data?.solarProductionMax)
    }

    func timeline(
        for configuration: SolarProductionAppIntent, in context: Context
    ) async -> Timeline<SolarProductionEntry> {
        var entries: [SolarProductionEntry] = []

        if context.isPreview {
            // A complication with generic data for preview
            entries.append(.previewData())
        } else {
            let data = try? await solarManager.fetchOverviewData(
                lastOverviewData: nil)

            print("Timeline-Data \(data?.currentSolarProduction ?? -1)")

            entries.append(
                SolarProductionEntry(
                    date: Date(),
                    currentProduction: data?.currentSolarProduction,
                    maxProduction: data?.solarProductionMax))
        }

        return Timeline(entries: entries, policy: .atEnd)
    }

    func recommendations() -> [AppIntentRecommendation<
        SolarProductionAppIntent
    >] {
        // Create an array with all the preconfigured widgets to show.
        [
            AppIntentRecommendation(
                intent: SolarProductionAppIntent(),
                description: "Current Solar Production")
        ]
    }

    //    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
    //        // Generate a list containing the contexts this widget is relevant in.
    //    }
}
