//
//  ChargingButtonView.swift
//  SolarManagerWatch Watch App
//
//  Created by Marc Dürst on 01.11.2024.
//

import SwiftUI

struct ChargingButtonView: View {
    @EnvironmentObject var model: BuildingStateViewModel
    @Binding var chargingMode: ChargingMode
    @Binding var chargingStation: ChargingStation

    @State private var showingPopup = false

    var body: some View {
        Button(action: {
            print("\(chargingMode) pressed")

            if isSimpleChargingMode(chargingMode: chargingMode) {
                Task {
                    await setSimpleChargingMode(
                        chargingStation: chargingStation,
                        chargingMode: chargingMode)
                }
            } else {
                showingPopup = true
            }

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
        .tint(
            getButtonTint(
                chargingMode: chargingMode,
                chargingStation: $chargingStation
                    .wrappedValue)
        )
        .sheet(isPresented: $showingPopup) {
            ChargingOptionsPopupView()
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
            return getColoredImage(
                systemName: "fluid.batteryblock", color: .yellow)
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

    private func getButtonTint(
        chargingMode: ChargingMode,
        chargingStation: ChargingStation
    ) -> Color? {
        return (chargingStation.chargingMode == chargingMode)
            ? .accent
            : .primary
    }

    private func isSimpleChargingMode(chargingMode: ChargingMode) -> Bool {
        return chargingMode == .alwaysCharge
            || chargingMode == .withSolarPower
            || chargingMode == .withSolarOrLowTariff
            || chargingMode == .minimalAndSolar
            || chargingMode == .off
    }

    private func setSimpleChargingMode(
        chargingStation: ChargingStation,
        chargingMode: ChargingMode
    ) async {
        guard isSimpleChargingMode(chargingMode: chargingMode) else {
            print("ERROR: \(chargingMode) is not a simple charging mode")
            return
        }

        await model.setCarCharging(
            sensorId: chargingStation.id,
            newCarCharging:
                ControlCarChargingRequest.init(chargingMode: chargingMode))
    }

}
