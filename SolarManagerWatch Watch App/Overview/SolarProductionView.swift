//
//  SolarProductionView.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 05.10.2024.
//


import SwiftUI

struct SolarProductionView: View {
    @Binding var currentSolarProduction: Double
    @Binding var maximumSolarProduction: Double
    
    var body: some View {
        VStack() {
            Gauge(
                value: currentSolarProduction,
                in: 0...maximumSolarProduction
            ) {
                Text("kW")
            } currentValueLabel: {
                Text(
                    String(
                        format: "%.1f",
                        currentSolarProduction)
                )
            }
            .gaugeStyle(.circular)
            .tint(Gradient(colors: [.blue, .green, .green, .green]))

            Image(systemName: "sun.max")
        }
    }
}
