//
//  SolarProductionView.swift
//  Solar Lens Watch App
//
//  Created by Marc Dürst on 23.11.2024.
//

import SwiftUI

struct SolarProductionWidgetView: View {
    // Get the widget's family.
    @Environment(\.widgetFamily) private var family

    var entry: SolarProductionEntry

    var body: some View {

        switch family {
        case .accessoryCircular:
            SolarProductionCircularWidgetView(
                currentProduction: entry.currentProduction,
                maxProduction: entry.maxProduction)

        case .accessoryCorner:
            SolarProductionCornerWidgetView(
                currentProduction: entry.currentProduction,
                maxProduction: entry.maxProduction)

        case .accessoryInline:
            Text("☀️ \(entry.currentProduction ?? 0) W")

        case .accessoryRectangular:
            Text("☀️ \(entry.currentProduction ?? 0) W")

        default:
            Image("AppIcon")
        }

    }
}

#Preview {
    SolarProductionWidgetView(
        entry: SolarProductionEntry(
            date: Date(),
            currentProduction: 3400,
            maxProduction: 11000))
}
