//
//  ConsumptionCircularWidgetView.swift
//  Solar Lens Watch App
//
//  Created by Marc Dürst on 23.11.2024.
//

import SwiftUI
import WidgetKit

struct ConsumptionCircularWidgetView: View {
    @Environment(\.widgetRenderingMode) var renderingMode

    var currentConsumption: Int?
    var carCharging: Bool?
    var consumptionFromSolar: Int?
    var consumptionFromBattery: Int?
    var consumptionFromGrid: Int?

    var body: some View {
        let current = Double(currentConsumption ?? 0) / 1000

        ZStack {
            AccessoryWidgetBackground()
            VStack {
                if carCharging ?? false {
                    Image(systemName: "car.side")
                } else {
                    Image(systemName: "house")
                }

                Text("\(String(format: "%.1f", current))")
                    .foregroundColor(
                        renderingMode == .fullColor ? .teal : .primary)
            }
        }.widgetLabel(getLabelText())
    }
    
    private func getLabelText() -> String {
        var text = "";
        if consumptionFromSolar ?? 0 > 50 {
            let solarConsumption = Double(consumptionFromSolar!) / 1000
            text = "☀️\(String(format: "%.1f", solarConsumption))"
        }
        
        if consumptionFromBattery ?? 0 > 50 {
            let batteryConsumption = Double(consumptionFromBattery!) / 1000
            text += "🔋\(String(format: "%.1f", batteryConsumption))"
        }
        
        if consumptionFromGrid ?? 0 > 50 {
            let gridConsumption = Double(consumptionFromGrid!) / 1000
            text += "🌐\(String(format: "%.1f", gridConsumption))"
        }
        
        return text
    }
}

#Preview("Zero") {
    ConsumptionCircularWidgetView(
        currentConsumption: 1230,
        carCharging: false,
        consumptionFromSolar: 1230,
        consumptionFromBattery: 0,
        consumptionFromGrid: 0
    )
}

#Preview("+Car") {
    ConsumptionCircularWidgetView(
        currentConsumption: 1230,
        carCharging: true,
        consumptionFromSolar: 1230,
        consumptionFromBattery: 0,
        consumptionFromGrid: 0
    )
}

#Preview("accented") {
    ConsumptionCircularWidgetView(
        currentConsumption: 1230,
        carCharging: true,
        consumptionFromSolar: 1230,
        consumptionFromBattery: 0,
        consumptionFromGrid: 0
    ).environment(\.widgetRenderingMode, .accented)
}

#Preview("vibrant") {
    ConsumptionCircularWidgetView(
        currentConsumption: 1230,
        carCharging: true,
        consumptionFromSolar: 1230,
        consumptionFromBattery: 0,
        consumptionFromGrid: 0
    ).environment(\.widgetRenderingMode, .vibrant)
}
