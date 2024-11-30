//
//  SolarProductionProvider.swift
//  Solar Lens Watch App
//
//  Created by Marc Dürst on 22.11.2024.
//

import Foundation
import WidgetKit

struct GenericWidgetProvider: AppIntentTimelineProvider {

    func placeholder(in context: Context) -> GenericEntry {
        return .previewData()
    }

    func snapshot(
        for configuration: GenericAppIntent, in context: Context
    ) async -> GenericEntry {

        if context.isPreview {
            // A complication with generic data for preview
            return .previewData()
        }
        
        return GenericEntry(
            date: Date())
    }

    func timeline(
        for configuration: GenericAppIntent, in context: Context
    ) async -> Timeline<GenericEntry> {
        var entries: [GenericEntry] = []

        if context.isPreview {
            // A complication with generic data for preview
            entries.append(.previewData())
        } else {
            entries.append(GenericEntry(date: Date()))
        }

        return Timeline(entries: entries, policy: .after(Date().addingTimeInterval(3600)))
    }

    func recommendations() -> [AppIntentRecommendation<
        GenericAppIntent
    >] {
        // Create an array with all the preconfigured widgets to show.
        [
            AppIntentRecommendation(
                intent: GenericAppIntent(),
                description: "App icon")
        ]
    }

    //    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
    //        // Generate a list containing the contexts this widget is relevant in.
    //    }
}
