//
//  ChargingModeConfiguration.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 09.11.2024.
//

import Foundation
import SwiftUI

class ChargingModeConfiguration: ObservableObject {
    @AppStorage("chargingModesVisibillity") private var chargingModeVisibillityData:
        Data?

    @Published var chargingModeVisibillity: [ChargingMode: Bool] = [
        .alwaysCharge: true,
        .withSolarPower: true,
        .withSolarOrLowTariff: true,
        .off: true,
        .constantCurrent: true,
        .minimalAndSolar: true,
        .minimumQuantity: true,
        .chargingTargetSoc: true,
    ]

    init() {
        if let data = chargingModeVisibillityData,
            let decodedData = try? JSONDecoder().decode(
                [ChargingMode: Bool].self, from: data)
        {
            chargingModeVisibillity = decodedData
        }
    }

    func changeChargingModeVisibillity(modes: [ChargingMode: Bool]) {
        for mode in modes {
            chargingModeVisibillity[mode.key] = mode.value
        }
        
        if let encodedData = try? JSONEncoder().encode(chargingModeVisibillity) {
            chargingModeVisibillityData = encodedData
        }
    }
}
