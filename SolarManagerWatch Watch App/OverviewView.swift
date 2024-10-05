//
//  OverviewView.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 29.09.2024.
//

import SwiftUI

struct OverviewView: View {
    @EnvironmentObject var model: BuildingStateViewModel

    @State private var solarProductionMinValue = 0.0
    @State private var solarProductionMaxValue = 11.0

    var body: some View {
        VStack {
            HStack {
                Gauge(
                    value: model.overviewData.currentSolarProduction,
                    in: solarProductionMinValue...solarProductionMaxValue
                ) {
                    Text("Solar")
                } currentValueLabel: {
                    Text(String(format: "%.1f", model.overviewData.currentSolarProduction))
                }
                .gaugeStyle(.circular)
            }
            Image(systemName: "house")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("House Overview")
            Text(
                "Solar Power: \(model.overviewData.currentSolarProduction, specifier:"%.2f")"
            )
        }
        .padding()
    }
}

#Preview {
    OverviewView()
        .environmentObject(BuildingStateViewModel())
}
