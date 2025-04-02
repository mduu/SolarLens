import SwiftUI

struct ChargingStationView: View {
    @Binding var station: ChargingStation
    @State var showChargingModeSelection: Bool = false

    var body: some View {
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
        .onTapGesture {
            showChargingModeSelection = true
        }
        .sheet(isPresented: $showChargingModeSelection) {
            ChargingModePickerView(
                station: station
            )
            .presentationDetents([.height(450)])
        }  // : sheet
    }
}

#Preview {
    ChargingStationView(
        station: .constant(
            ChargingStation(
                id: "2134",
                name: "Station 2",
                chargingMode: .withSolarPower,
                priority: 1,
                currentPower: 0,
                signal: .connected
            )
        ))
}
