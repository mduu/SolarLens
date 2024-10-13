//
//  BatteryView.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 05.10.2024.
//

import SwiftUI

struct BatteryView: View {
    @Binding var currentBatteryLevel: Int?
    @Binding var currentChargeRate: Int?

    var body: some View {
        if currentBatteryLevel != nil && currentChargeRate != nil {
            
            VStack(spacing: 1) {
                Gauge(
                    value: Double(currentBatteryLevel ?? 0),
                    in: 0...100
                ) {
                } currentValueLabel: {
                    Text(
                        String(
                            format: "%.0f%%",
                            Double(currentBatteryLevel ?? 0))
                    )
                    .foregroundStyle(getColor())
                }
                .gaugeStyle(.accessoryCircular)
                .tint(Gradient(colors: [.red, .green, .green, .green]))

                Image(systemName: "battery.100percent")
            }
            .padding()
        }
    }

    private func getColor() -> Color {
        currentBatteryLevel ?? 0 >= 10 ? .primary : .red
    }
}
