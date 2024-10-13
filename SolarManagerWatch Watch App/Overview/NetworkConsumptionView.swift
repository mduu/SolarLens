//
//  NetworkConsumptionView.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 05.10.2024.
//


import SwiftUI

struct NetworkConsumptionView: View {
    @Binding var currentNetworkConsumption: Int
    @Binding var maximumNetworkConsumption: Int

    var body: some View {
        VStack(spacing: 1) {
            Gauge(
                value: Double(currentNetworkConsumption) / 1000,
                in: 0...Double(maximumNetworkConsumption) / 1000
            ) {
                Text("kW")
            } currentValueLabel: {
                Text(
                    String(
                        format: "%.1f",
                        Double(currentNetworkConsumption) / 1000)
                )
            }
            .gaugeStyle(.accessoryCircular)
            .tint(Gradient(colors: [.green, .orange, .orange, .red]))

            Image(systemName: "network")
        }
    }
}
