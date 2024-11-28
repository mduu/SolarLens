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

    var body: some View {
        let current = Double(currentConsumption ?? 0) / 1000

        Text("\(String(format: "%.1f", current)) kW")
            .foregroundColor(renderingMode == .fullColor ? .green : .primary)
            .widgetCurvesContent()
            .widgetLabel {
                if carCharging ?? false {
                    Image(systemName: "car.side")
                        .symbolEffect(
                            .pulse.wholeSymbol, options: .repeat(.continuous))
                    Text("Charging")
                } else {
                    Image(systemName: "house")
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
