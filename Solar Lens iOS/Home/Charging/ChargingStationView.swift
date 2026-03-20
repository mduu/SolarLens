import SwiftUI

struct ChargingStationView: View {
    @Binding var station: ChargingStation
    @State var showChargingModeSelection: Bool = false

    var body: some View {
        CircularInstrument(
            borderColor: .blue,
            label: LocalizedStringResource(stringLiteral: station.name),
            small: true,
            isTouchable: true
        ) {
            Image(systemName: station.currentPower > 0 ? "ev.charger.fill" : "ev.charger")
                .resizable()
                .scaledToFit()
                .symbolEffect(
                    .pulse.wholeSymbol,
                    options: .repeat(.continuous),
                    isActive: station.currentPower > 0
                )
                .frame(maxHeight: 20)
                .foregroundColor(.black)
        }
        .frame(maxWidth: 60)
        .onTapGesture {
            showChargingModeSelection = true
        }
        .sheet(isPresented: $showChargingModeSelection) {
            ChargingModePickerView(
                station: station
            )
            .presentationDetents([.large])
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
