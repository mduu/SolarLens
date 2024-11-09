//
//  ChargingModeConfiguration.swift
//  Solar Lens Watch App
//
//  Created by Marc Dürst on 09.11.2024.
//

import SwiftUI

struct ChargingModeConfigurationView: View {
    @State private var chargingModeConfiguration = ChargingModeConfiguration()

    @State private var modeAllwaysOn: Bool = true
    @State private var modeWithSolarPower: Bool = true
    @State private var modeWithSolarOrLowTariff: Bool = true
    @State private var modeOff: Bool = true
    @State private var modeConstantCurrent: Bool = true
    @State private var modeMinimalAndSolar: Bool = true
    @State private var modeMinimumQuantity: Bool = true
    @State private var modeChargingTargetSoc: Bool = false

    init() {
        let modeVisitability = $chargingModeConfiguration
            .chargingModeVisibillity.wrappedValue
        self.modeAllwaysOn = modeVisitability[.alwaysCharge]!
        self.modeWithSolarPower = modeVisitability[.withSolarPower]!
        self.modeWithSolarOrLowTariff = modeVisitability[.withSolarOrLowTariff]!
        self.modeOff = modeVisitability[.off]!
        self.modeConstantCurrent = modeVisitability[.constantCurrent]!
        self.modeMinimalAndSolar = modeVisitability[.minimalAndSolar]!
        self.modeMinimumQuantity = modeVisitability[.minimumQuantity]!
        self.modeChargingTargetSoc = modeVisitability[.chargingTargetSoc]!
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                Text("Personalize")
                    .font(.headline)
                    .foregroundColor(.accent)

                Toggle(isOn: $modeAllwaysOn) {
                    ChargingModelLabelView(chargingMode: .alwaysCharge)
                }

                Toggle(isOn: $modeWithSolarPower) {
                    ChargingModelLabelView(chargingMode: .withSolarPower)
                }

                Toggle(isOn: $modeWithSolarOrLowTariff) {
                    ChargingModelLabelView(chargingMode: .withSolarOrLowTariff)
                }

                Toggle(isOn: $modeOff) {
                    ChargingModelLabelView(chargingMode: .off)
                }

                Toggle(isOn: $modeConstantCurrent) {
                    ChargingModelLabelView(chargingMode: .constantCurrent)
                }

                Toggle(isOn: $modeMinimalAndSolar) {
                    ChargingModelLabelView(chargingMode: .minimalAndSolar)
                }

                Toggle(isOn: $modeMinimumQuantity) {
                    ChargingModelLabelView(chargingMode: .minimumQuantity)
                }

                Toggle(isOn: $modeChargingTargetSoc) {
                    ChargingModelLabelView(chargingMode: .chargingTargetSoc)
                }
            }
            .onChange(of: modeAllwaysOn) { updateSettings() }
            .onChange(of: modeOff) { updateSettings() }
            .onChange(of: modeConstantCurrent) { updateSettings() }
            .onChange(of: modeWithSolarPower) { updateSettings() }
            .onChange(of: modeMinimalAndSolar) { updateSettings() }
            .onChange(of: modeWithSolarOrLowTariff) { updateSettings() }
            .onChange(of: modeMinimumQuantity) { updateSettings() }
            .onChange(of: modeChargingTargetSoc) { updateSettings() }
        }
    }

    private func updateSettings() {
        let modes: [ChargingMode: Bool] = [
            .alwaysCharge : modeAllwaysOn,
            .chargingTargetSoc : modeChargingTargetSoc,
            .constantCurrent : modeConstantCurrent,
            .minimalAndSolar : modeMinimalAndSolar,
            .minimumQuantity : modeMinimumQuantity,
            .off : modeOff,
            .withSolarPower : modeWithSolarPower,
            .withSolarOrLowTariff : modeWithSolarOrLowTariff
        ]
        
        chargingModeConfiguration.changeChargingModeVisibillity(modes: modes)
        
        print("Visibillities settings updated")
    }
}

#Preview {
    ChargingModeConfigurationView()
}
