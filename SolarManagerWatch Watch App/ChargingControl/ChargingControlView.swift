//
//  ChargingControlView.swift
//  SolarManagerWatch Watch App
//
//  Created by Marc Dürst on 25.10.2024.
//

import SwiftUI

struct ChargingControlView: View {
    @EnvironmentObject var model: BuildingStateViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                
                Spacer()

                ForEach($model.overviewData.chargingStations, id: \.id) {
                    chargingStation in

                    VStack(alignment: .leading, spacing: 3) {
                        if model.overviewData.chargingStations.count > 1 {
                            Text("\(chargingStation.name.wrappedValue)")
                                .font(.subheadline)
                        }

                        ForEach(ChargingMode.allCases, id: \.self) {
                            chargingMode in

                            Button(action: {
                                print("Model: \(chargingMode) pressed")
                            }) {
                                HStack(spacing: 2) {
                                    getModeImage(for: chargingMode)
                                        .padding(.leading, 3)

                                    Text(
                                        "\(getCharingModeName(for: chargingMode))"
                                    ).multilineTextAlignment(.leading)

                                    Spacer(minLength: 0)
                                }.frame(alignment: .leading)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.all, 0)

                        }
                    }
                }
            }
            .navigationTitle("Charging")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func getCharingModeName(for mode: ChargingMode) -> String {
        switch mode {
        case .withSolarPower:
            return "Solar only"
        case .withSolarOrLowTariff:
            return "Solar & Tariff"
        case .alwaysCharge:
            return "Always"
        case .off:
            return "Off"
        case .constantCurrent:
            return "Constant"
        case .minimalAndSolar:
            return "Minimal & Solar"
        case .minimumQuantity:
            return "Minimal"
        case .chargingTargetSoc:
            return "Car %"
        }
    }

    private func getModeImage(for mode: ChargingMode) -> some View {
        switch mode {
        case .withSolarPower:
            return getColoredImage(systemName: "sun.max", color: .yellow)
        case .withSolarOrLowTariff:
            return getColoredImage(systemName: "sunset", color: .orange)
        case .alwaysCharge:
            return getColoredImage(systemName: "24.circle", color: .teal)
        case .off:
            return getColoredImage(systemName: "poweroff", color: .red)
        case .constantCurrent:
            return getColoredImage(systemName: "glowplug", color: .green)
        case .minimalAndSolar:
            return getColoredImage(systemName: "glowplug", color: .indigo)
        case .minimumQuantity:
            return getColoredImage(
                systemName: "minus.plus.and.fluid.batteryblock", color: .blue)
        case .chargingTargetSoc:
            return getColoredImage(systemName: "bolt.car", color: .purple)
        }
    }

    private func getColoredImage(systemName: String, color: Color = .primary)
        -> some View
    {
        return Image(systemName: systemName)
            .foregroundColor(color)
    }
}

#Preview {
    ChargingControlView()
        .environmentObject(
            BuildingStateViewModel.fake(
                overviewData: .init(
                    currentSolarProduction: 4550,
                    currentOverallConsumption: 1200,
                    currentBatteryLevel: 78,
                    currentBatteryChargeRate: 3400,
                    currentSolarToGrid: 10,
                    currentGridToHouse: 0,
                    currentSolarToHouse: 1200,
                    solarProductionMax: 11000,
                    hasConnectionError: false,
                    lastUpdated: Date(),
                    isAnyCarCharing: false,
                    chargingStations: [
                        .init(
                            id: "42",
                            name: "Keba",
                            chargingMode: ChargingMode.withSolarPower,
                            priority: 1,
                            currentPower: 0,
                            signal: SensorConnectionStatus.connected)
                    ]
                )
            ))
}
