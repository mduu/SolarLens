//
//  SolarProductionView.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 05.10.2024.
//


import SwiftUI

struct SolarProductionView: View {
    @Binding var currentSolarProduction: Int
    @Binding var maximumSolarProduction: Int
    
    var body: some View {
        VStack() {
            Gauge(
                value: Double(currentSolarProduction / 1000),
                in: 0...Double(maximumSolarProduction / 1000)
            ) {
                Text("kW")
            } currentValueLabel: {
                Text(
                    String(
                        format: "%.1f",
                        Double(currentSolarProduction / 1000))
                )
            }
            .gaugeStyle(.circular)
            .tint(Gradient(colors: [.blue, .green, .green, .green]))

            Image(systemName: "sun.max")
        }
    }
}
