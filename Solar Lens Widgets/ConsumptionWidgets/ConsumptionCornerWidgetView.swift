//
//  ConsumptionCornerWidgetView.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 23.11.2024.
//

import SwiftUI
import SwiftUICore
import WidgetKit

struct ConsumptionCornerWidgetView: View {
    @Environment(\.widgetRenderingMode) var renderingMode

    var currentConsumption: Int?
    var carCharging: Bool?
    var consumptionFromSolar: Int?
    var consumptionFromBattery: Int?
    var consumptionFromGrid: Int?

    var body: some View {
        Text(getText())
            .foregroundColor(renderingMode == .fullColor ? .teal : .primary)
            .widgetCurvesContent()
            .widgetLabel {
                Text(getLabelText())
            }

    }
    
    private func getText() -> String {
        let current = Double(currentConsumption ?? 0) / 1000

        var text = "\(String(format: "%.1f", current)) kW";
        if carCharging ?? false {
            text += " 🚗"
        }
        
        return text
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

#Preview("Consumption") {
    ConsumptionCornerWidgetView()
}

#Preview("+ Car") {
    ConsumptionCornerWidgetView(
        currentConsumption: 1230,
        carCharging: true
    )
}

#Preview("accented") {
    ConsumptionCornerWidgetView(
        currentConsumption: 1230,
        carCharging: true
    ).environment(\.widgetRenderingMode, .accented)
}

#Preview("vibrant") {
    ConsumptionCornerWidgetView(
        currentConsumption: 1230,
        carCharging: true
    ).environment(\.widgetRenderingMode, .vibrant)
}
