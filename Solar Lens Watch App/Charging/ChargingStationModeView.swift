import SwiftUICore

struct ChargingStationModeView: View {
    var isTheOnlyOne: Bool
    var chargingStation: ChargingStation
    var chargingModeConfiguration: ChargingModeConfiguration

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
                        chargingMode: chargingMode,
                        chargingStation: chargingStation
                    )  // :ChargingButtonView

                }  // :if
            }  // :ForEach
        }  // :VStack
    }
}
