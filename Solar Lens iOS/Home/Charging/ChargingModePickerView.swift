import SwiftUI

struct ChargingModePickerView: View {
    @Binding var station: ChargingStation
    @State var chargingModeConfiguration = ChargingModeConfiguration()

    var body: some View {

        List {
            Text("Choose charging mode:")
                .font(.caption)

            ForEach(ChargingMode.allCases, id: \.self) {
                chargingMode in

                if chargingModeConfiguration.chargingModeVisibillity[
                    chargingMode] ?? true
                {

                    ChargingButtonView(
                        chargingMode: chargingMode,
                        chargingStation: station,
                        largeButton: true
                    )  // :ChargingButtonView

                }  // :if
            }  // :ForEach
        }  // :List

    }
}

#Preview {
    ChargingModePickerView(
        station: .constant(
            ChargingStation(
                id: "2134",
                name: "Station 2",
                chargingMode: .withSolarPower,
                priority: 1,
                currentPower: 0,
                signal: .connected
            )
        )
    )
}
