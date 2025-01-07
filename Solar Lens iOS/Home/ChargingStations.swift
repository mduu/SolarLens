//
//  ChargingStations.swift
//  Solar Lens
//
//  Created by Marc Dürst on 07.01.2025.
//

import SwiftUI

struct ChargingStations: View {
    @Binding var chargingStation: [ChargingStation]

    var body: some View {
        let stations = chargingStation.sorted { $0.priority < $1.priority }
        
        HStack {
            ForEach(stations) { station in
                CircularInstrument(
                    borderColor: .blue,
                    label: LocalizedStringResource(stringLiteral: station.name),
                    small: true
                ) {
                    if station.currentPower > 0 {
                        Image(systemName: "car.side")
                            .resizable()
                            .scaledToFit()
                            .symbolEffect(
                                .pulse.wholeSymbol,
                                options: .repeat(.continuous)
                            )
                            .frame(maxHeight: 20)
                            .foregroundColor(.black)
                    } else {
                        Image(systemName: "ev.charger")
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 20)
                            .foregroundColor(.black)
                    }
                }
                .frame(maxWidth: 60)
            }

        }.frame(maxWidth: 120)
    }

}

#Preview {
    ChargingStations(
        chargingStation: .constant([
            ChargingStation(
                id: "2134",
                name: "Station 2",
                chargingMode: .withSolarPower,
                priority: 1,
                currentPower: 0,
                signal: .connected
            ),
            ChargingStation(
                id: "435",
                name: "Station 1",
                chargingMode: .withSolarOrLowTariff,
                priority: 0,
                currentPower: 5600,
                signal: .connected
            ),
        ])
    )
}
