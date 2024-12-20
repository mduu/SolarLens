//
//  ChargingStationModeView.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 02.11.2024.
//

import SwiftUICore

struct ChargingStationModeView: View {
    @Binding var isTheOnlyOne: Bool
    @Binding var chargingStation: ChargingStation
    @Binding var chargingModeConfiguration: ChargingModeConfiguration

    var body: some View {
        VStack {
            if !isTheOnlyOne {
                Text("\(chargingStation.name)")
                    .font(.subheadline)
            }  // :if

            ForEach(ChargingMode.allCases, id: \.self) {
                chargingMode in

                if chargingModeConfiguration.chargingModeVisibillity[chargingMode] ?? true {

                    ChargingButtonView(
                        chargingMode: .constant(chargingMode),
                        chargingStation: .constant(chargingStation)
                    )  // :ChargingButtonView

                }  // :if
            }  // :ForEach
        }  // :VStack
    }
}
