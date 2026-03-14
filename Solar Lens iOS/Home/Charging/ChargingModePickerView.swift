import SwiftUI

struct ChargingModePickerView: View {
    @Environment(CurrentBuildingState.self) var buildingState: CurrentBuildingState
    var station: ChargingStation
    @State var chargingModeConfiguration = ChargingModeConfiguration()

    var body: some View {

        List {
            // Charging info header
            HStack(spacing: 16) {
                Image(systemName: "car.side")
                    .font(.title3)
                    .foregroundStyle(.green)
                    .symbolEffect(
                        .pulse.wholeSymbol,
                        options: .repeat(.continuous),
                        isActive: (buildingState.chargingInfos?.currentCharging ?? 0) > 0
                    )

                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let totalToday = buildingState.chargingInfos?.totalCharedToday {
                        Text(String(format: "%.1f kWh", totalToday / 1000))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    } else {
                        Text("–")
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()
                    .frame(height: 20)

                HStack(spacing: 4) {
                    Image(systemName: "bolt")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let currentPower = buildingState.chargingInfos?.currentCharging {
                        Text(String(format: "%.1f kW", Double(currentPower) / 1000))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    } else {
                        Text("–")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .listRowSeparator(.hidden)

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
        .task {
            await buildingState.fetchChargingInfos()
        }

    }
}

#Preview {
    ChargingModePickerView(
        station: ChargingStation(
            id: "2134",
            name: "Station 2",
            chargingMode: .withSolarPower,
            priority: 1,
            currentPower: 0,
            signal: .connected
        )
    )
}
