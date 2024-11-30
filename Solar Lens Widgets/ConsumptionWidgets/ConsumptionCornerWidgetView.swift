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
        let current = Double(currentConsumption ?? 0) / 1000

        Text("\(String(format: "%.1f", current)) kW")
            .foregroundColor(renderingMode == .fullColor ? .green : .primary)
            .widgetCurvesContent()
            .widgetLabel {
                if consumptionFromSolar ?? 0 > 0 {
                    Image(systemName: "sun.max")
                    Text("\(String(format: "%.1f", consumptionFromSolar ?? 0 / 1000))")
                }
                
                if consumptionFromBattery ?? 0 > 0 {
                    Image(systemName: "battery.100percent")
                    Text("\(String(format: "%.1f", consumptionFromBattery ?? 0 / 1000))")
                }
                
                if consumptionFromGrid ?? 0 > 0 {
                    Image(systemName: "network")
                    Text("\(String(format: "%.1f", consumptionFromGrid ?? 0 / 1000))")
                }
                
                if carCharging ?? false {
                    Image(systemName: "car.side")
                        .symbolEffect(
                            .pulse.wholeSymbol, options: .repeat(.continuous))
                    Text("Charging")
                }
            }

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
