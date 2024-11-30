//
//  SolarProductionAppIntent.swift
//  Solar Lens Watch App
//
//  Created by Marc Dürst on 22.11.2024.
//

import AppIntents
import Foundation
import WidgetKit

struct GenericAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "App Icon"
}

struct GenericEntry: TimelineEntry {
    var date: Date

    static func previewData() -> GenericEntry {
        .init(date: Date())
    }
}
