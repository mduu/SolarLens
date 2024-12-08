//
//  SolarProductionView.swift
//  Solar Lens Watch App
//
//  Created by Marc Dürst on 23.11.2024.
//

import SwiftUI
import WidgetKit

struct SolarProductionWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) var renderingMode
    @Environment(\.showsWidgetLabel) private var showsWidgetLabel

    var entry: SolarProductionEntry

    var body: some View {
        let current = Double(entry.currentProduction ?? 0) / 1000
        let max = Double(entry.maxProduction ?? 0) / 1000

        switch family {
            
        case .accessoryCircular:
            
            ZStack {
                AccessoryWidgetBackground()

                if showsWidgetLabel {
                
                    ZStack {
                        AccessoryWidgetBackground()
                        if renderingMode == .fullColor {
                            Image("solarlens")
                        } else {
                            Image("solarlenstrans")
                        }
                    } // :ZStack
                    .widgetLabel {
                        Text("☀️ \(String(format: "%.1f kW", current))")
                    } // :widgetLabel
                    
                } else {
                    
                    Gauge(
                        value: current,
                        in: 0...max
                    ) {
                        Image(systemName: "sun.max")
                    } currentValueLabel: {
                        Text("\(String(format: "%.1f", current))")
                    }
                    .gaugeStyle(.circular)
                    .tint(renderingMode == .fullColor ? getGaugeStyle() : nil)
                
                } // :else
            } // :ZStack
            .containerBackground(for: .widget) { Color.accentColor }

        case .accessoryCorner:
            
            Text("\(String(format: "%.1f", current)) kW")
                .foregroundColor(renderingMode == .fullColor ? .yellow : nil)
                .widgetCurvesContent()
                .widgetLabel {
                    Gauge(
                        value: current,
                        in: 0...max
                    ) {
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
                } // :widgetLabel
                .containerBackground(for: .widget) { Color.accentColor }

        case .accessoryInline:
            
            Text("☀️ \(entry.currentProduction ?? 0) W")
                .containerBackground(for: .widget) { Color.accentColor }

        case .accessoryRectangular:
            
            Text("☀️ \(entry.currentProduction ?? 0) W")
                .containerBackground(for: .widget) { Color.accentColor }

        default:
            Image("AppIcon")
                .containerBackground(for: .widget) { Color.accentColor }
        }

    }

    func getGaugeStyle() -> Gradient {
        return entry.currentProduction ?? 0 < 50
            ? Gradient(colors: [.gray, .gray])
            : Gradient(colors: [.blue, .yellow, .orange])
    }
}

struct SolarProductionWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview for circular
            SolarProductionWidgetView(
                entry: SolarProductionEntry.previewData()
            )
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            .previewDisplayName("Circular")
            
            // Preview for corner
            SolarProductionWidgetView(
                entry: SolarProductionEntry.previewData()
            )
            .previewContext(WidgetPreviewContext(family: .accessoryCorner))
            .previewDisplayName("Corner")

            // Preview for inline
            SolarProductionWidgetView(
                entry: SolarProductionEntry.previewData()
            )
            .previewContext(WidgetPreviewContext(family: .accessoryInline))
            .previewDisplayName("Inline")
        }
    }
}
