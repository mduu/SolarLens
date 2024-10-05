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
                Text("Bat")
            } currentValueLabel: {
                Text(
                    String(
                        format: "%.0f%%",
                        currentBatteryLevel)
                )
            }
            .gaugeStyle(.accessoryCircularCapacity)
            
            Image(systemName: "battery.100percent")
        }
    }
}