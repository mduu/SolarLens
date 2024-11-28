//
//  SolarProductionCornerWidgetView.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 23.11.2024.
//

import SwiftUI
import SwiftUICore
import WidgetKit

struct SolarProductionCornerWidgetView: View {
    @Environment(\.widgetRenderingMode) var renderingMode

    var currentProduction: Int?
    var maxProduction: Double?

    var body: some View {
        let current = Double(currentProduction ?? 0) / 1000
        let max = Double(maxProduction ?? 0) / 1000

        Text("\(String(format: "%.1f", current)) kW")
            .foregroundColor(renderingMode == .fullColor ? .yellow : nil)
            .widgetCurvesContent()
            .widgetLabel {
                Gauge(value: current) {
                    Text("kW")
                } currentValueLabel: {
                    Text("\(String(format: "%.1f", current))")
                } minimumValueLabel: {
                    Text("0")
                } maximumValueLabel: {
                    Text("\(String(format: "%.0f", max))")
                }
                .gaugeStyle(.automatic)
                .tint(renderingMode == .fullColor ? getGaugeStyle() : nil)
            }
    }

    func getGaugeStyle() -> Gradient {
        return currentProduction ?? 0 < 50
            ? Gradient(colors: [.gray, .gray])
            : Gradient(colors: [.blue, .yellow, .orange])
    }
}

#Preview("Zero") {
    SolarProductionCornerWidgetView()
}

#Preview("4kW") {
    SolarProductionCornerWidgetView(
        currentProduction: 4000,
        maxProduction: 11000
    )
}

#Preview("accented") {
    SolarProductionCornerWidgetView(
        currentProduction: 4000,
        maxProduction: 11000
    ).environment(\.widgetRenderingMode, .accented)
}

#Preview("vibrant") {
    SolarProductionCornerWidgetView(
        currentProduction: 4000,
        maxProduction: 11000
    ).environment(\.widgetRenderingMode, .vibrant)
}
