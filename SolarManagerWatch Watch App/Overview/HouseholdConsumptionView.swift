//
//  HouseholdConsumptionView.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 05.10.2024.
//


import SwiftUI

struct HouseholdConsumptionView: View {
    @Binding var currentOverallConsumption: Int
    @Binding var consumptionMaxValue: Int

    var body: some View {
        VStack(spacing: 0) {
            Gauge(
                value: Double(currentOverallConsumption / 1000),
                in:
                    0...Double(consumptionMaxValue / 1000)
            ) {
                Text("kW")
            } currentValueLabel: {
                Text(
                    String(
                        format: "%.1f",
                        Double(currentOverallConsumption / 1000))
                )
            }
            .gaugeStyle(.circular)
            .tint(Gradient(colors: [.green, .orange]))

            Image(systemName: "house")
        }
    }
}
