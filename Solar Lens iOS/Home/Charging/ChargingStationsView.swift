import SwiftUI

struct ChargingStationsView: View {
    var chargingStation: [ChargingStation]
    var isVertical: Bool = true

    var body: some View {
        let stations = chargingStation.sorted { $0.priority < $1.priority }

        if isVertical {
            
            HStack {
                ForEach(stations) { station in
                    ChargingStationView(station: .constant(station))
                }
            }.frame(maxWidth: 120)
            
        } else {
            
            VStack {
                ForEach(stations) { station in
                    ChargingStationView(station: .constant(station))
                }
            }.frame(maxHeight: 120)
            
        }
    }

}

#Preview("Vertical") {
    ChargingStationsView(
        chargingStation: [
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
        ]
    )
}

#Preview("Horizontal") {
    ChargingStationsView(
        chargingStation: [
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
        ],
        isVertical: false
    )
}
