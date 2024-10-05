//
//  HouseholdConsumptionView.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 05.10.2024.
//


import SwiftUI

struct HouseholdConsumptionView: View {
    @Binding var currentOverallConsumption: Double
    @Binding var consumptionMaxValue: Double

    var body: some View {
        VStack(spacing: 0) {
            Gauge(
                value: currentOverallConsumption,
                in:
                    0...consumptionMaxValue
            ) {
                Text("kW")
            } currentValueLabel: {
                Text(
                    String(
                        format: "%.1f",
                        currentOverallConsumption)
                )
            }
            .gaugeStyle(.circular)

            Image(systemName: "house")
        }
    }
}