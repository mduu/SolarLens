import SwiftUI

struct ChargingModePickerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(CurrentBuildingState.self) var buildingState: CurrentBuildingState
    var station: ChargingStation
    @State var chargingModeConfiguration = ChargingModeConfiguration()

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [Color(red: 0.05, green: 0.06, blue: 0.1), Color(red: 0.05, green: 0.05, blue: 0.05)]
                        : [Color(red: 0.94, green: 0.95, blue: 1.0), .white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Status card
                        HStack(spacing: 16) {
                            Image(systemName: "car.side")
                                .font(.title2)
                                .foregroundStyle(.blue)
                                .symbolEffect(
                                    .pulse.wholeSymbol,
                                    options: .repeat(.continuous),
                                    isActive: (buildingState.chargingInfos?.currentCharging ?? 0) > 0
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: "bolt")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if let currentPower = buildingState.chargingInfos?.currentCharging {
                                        Text(String(format: "%.1f kW", Double(currentPower) / 1000))
                                            .font(.headline)
                                            .fontWeight(.bold)
                                    } else {
                                        Text("–")
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                HStack(spacing: 4) {
                                    Image(systemName: "calendar")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if let totalToday = buildingState.chargingInfos?.totalCharedToday {
                                        Text(String(format: "%.1f kWh today", totalToday / 1000))
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Text("–")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }

                            Spacer()
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                        )

                        // Mode picker card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Charging mode")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            ForEach(ChargingMode.allCases, id: \.self) { chargingMode in
                                if chargingModeConfiguration.chargingModeVisibillity[chargingMode] ?? true {
                                    ChargingButtonView(
                                        chargingMode: chargingMode,
                                        chargingStation: station,
                                        largeButton: true
                                    )
                                }
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                        )
                    }
                    .padding()
                }
            }
            .navigationTitle("Charging")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
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
