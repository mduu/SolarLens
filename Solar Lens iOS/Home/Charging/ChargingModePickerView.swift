import SwiftUI

struct ChargingModePickerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(CurrentBuildingState.self) var buildingState: CurrentBuildingState
    var station: ChargingStation
    @State var chargingModeConfiguration = ChargingModeConfiguration()
    @State private var showingOptionsPopup = false
    @State private var popupMode: ChargingMode?

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
                            ZStack {
                                Circle()
                                    .fill(.blue.opacity(0.12))
                                    .frame(width: 48, height: 48)
                                Image(systemName: station.currentPower > 0 ? "car.side" : "ev.charger")
                                    .font(.title3)
                                    .foregroundStyle(.blue)
                                    .symbolEffect(
                                        .pulse.wholeSymbol,
                                        options: .repeat(.continuous),
                                        isActive: (buildingState.chargingInfos?.currentCharging ?? 0) > 0
                                    )
                            }

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
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("Charging mode")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            let visibleModes = ChargingMode.allCases.filter {
                                chargingModeConfiguration.chargingModeVisibillity[$0] ?? true
                            }

                            ForEach(visibleModes, id: \.self) { mode in
                                chargingModeRow(mode: mode)
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
            .navigationTitle(station.name)
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
            .sheet(isPresented: $showingOptionsPopup) {
                if let popupMode {
                    ChargingOptionsPopupView(
                        chargingMode: popupMode,
                        chargingStation: station
                    )
                    .presentationDetents([.height(300)])
                }
            }
        }
        .task {
            await buildingState.fetchChargingInfos()
        }
    }

    // MARK: - Mode Row

    @ViewBuilder
    private func chargingModeRow(mode: ChargingMode) -> some View {
        let isSelected = station.chargingMode == mode
        let accentColor = modeColor(for: mode)

        Button {
            if mode.isSimpleChargingMode() {
                Task {
                    await buildingState.setCarCharging(
                        sensorId: station.id,
                        newCarCharging: ControlCarChargingRequest(chargingMode: mode)
                    )
                }
            } else {
                popupMode = mode
                showingOptionsPopup = true
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(accentColor.opacity(isSelected ? 0.2 : 0.08))
                        .frame(width: 36, height: 36)
                    modeIcon(for: mode)
                        .font(.system(size: 16))
                        .foregroundStyle(accentColor)
                }

                VStack(alignment: .leading, spacing: 1) {
                    ChargingModelLabelView(chargingMode: mode)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(.primary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(accentColor)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected
                          ? accentColor.opacity(colorScheme == .dark ? 0.12 : 0.08)
                          : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isSelected ? accentColor.opacity(0.4) : Color.primary.opacity(0.08),
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    // MARK: - Mode Styling

    private func modeIcon(for mode: ChargingMode) -> Image {
        switch mode {
        case .withSolarPower: Image(systemName: "sun.max")
        case .withSolarOrLowTariff: Image(systemName: "sunset")
        case .alwaysCharge: Image(systemName: "24.circle")
        case .off: Image(systemName: "poweroff")
        case .constantCurrent: Image(systemName: "glowplug")
        case .minimalAndSolar: Image(systemName: "fluid.batteryblock")
        case .minimumQuantity: Image(systemName: "minus.plus.and.fluid.batteryblock")
        case .chargingTargetSoc: Image(systemName: "bolt.car")
        }
    }

    private func modeColor(for mode: ChargingMode) -> Color {
        switch mode {
        case .withSolarPower: .yellow
        case .withSolarOrLowTariff: .orange
        case .alwaysCharge: .teal
        case .off: .red
        case .constantCurrent: .green
        case .minimalAndSolar: .yellow
        case .minimumQuantity: .blue
        case .chargingTargetSoc: .purple
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
