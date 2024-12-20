//
//  ChargingModeLabelView.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 09.11.2024.
//

import SwiftUI

struct ChargingModelLabelView: View {
    let chargingMode: ChargingMode
    
    var body: some View {
        Text(getCharingModeName(mode: chargingMode))
            .multilineTextAlignment(.leading)
    }
    
    private func getCharingModeName(mode: ChargingMode) -> LocalizedStringKey {
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
}

#Preview {
    ChargingModelLabelView(chargingMode: .withSolarPower)
}
