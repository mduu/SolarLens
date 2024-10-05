//
//  BatteryView.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 05.10.2024.
//

import SwiftUI

struct BatteryView: View {
    @Binding var currentBatteryLevel: Double
    @Binding var currentChargeRate: Double

    var body: some View {
        VStack(spacing: 1) {
            Gauge(
                value: currentBatteryLevel,
                in: 0...100
            ) {
            } currentValueLabel: {
                Text(
                    String(
                        format: "%.0f%%",
                        currentBatteryLevel)
                )
                .foregroundStyle(getColor())
            }
            .gaugeStyle(.accessoryCircular)
            .tint(Gradient(colors: [.red, .green, .green, .green]))

            Image(systemName: "battery.100percent")
        }
    }

    private func getColor() -> Color {
        currentBatteryLevel >= 10 ? .primary : .red
    }
}
