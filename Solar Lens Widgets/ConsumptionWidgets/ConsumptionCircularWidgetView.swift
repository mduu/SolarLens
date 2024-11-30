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
                        .symbolEffect(
                            .pulse.wholeSymbol, options: .repeat(.continuous))
                } else {
                    Image(systemName: "house")
                }

                Text("\(String(format: "%.1f", current))")
                    .foregroundColor(
                        renderingMode == .fullColor ? .green : .primary)
            }
        }
    }
}

#Preview("Zero") {
    ConsumptionCircularWidgetView(
        currentConsumption: 1230
    )
}

#Preview("+Car") {
    ConsumptionCircularWidgetView(
        currentConsumption: 1230,
        carCharging: true
    )
}

#Preview("accented") {
    ConsumptionCircularWidgetView(
        currentConsumption: 1230,
        carCharging: true
    ).environment(\.widgetRenderingMode, .accented)
}

#Preview("vibrant") {
    ConsumptionCircularWidgetView(
        currentConsumption: 1230,
        carCharging: true
    ).environment(\.widgetRenderingMode, .vibrant)
}
