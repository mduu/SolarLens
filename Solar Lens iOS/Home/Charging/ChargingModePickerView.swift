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
                        // Car info cards
                        let cars = buildingState.overviewData.cars
                        if !cars.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 4) {
                                    Image(systemName: "car.side")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("Cars")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                let rows = stride(from: 0, to: cars.count, by: 2).map {
                                    Array(cars[$0..<min($0 + 2, cars.count)])
                                }
                                ForEach(rows, id: \.first!.id) { row in
                                    HStack(spacing: 10) {
                                        ForEach(row) { car in
                                            carCard(car: car)
                                        }
                                        if row.count == 1 && cars.count > 1 {
                                            Spacer().frame(maxWidth: .infinity)
                                        }
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

                        // Charging station status + mode card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "ev.charger")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("Charging Station")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            // Today amounts
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(.blue.opacity(0.12))
                                        .frame(width: 48, height: 48)
                                    Image(systemName: station.currentPower > 0 ? "ev.charger.fill" : "ev.charger")
                                        .font(.title3)
                                        .foregroundStyle(.secondary)
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

                            Divider()

                            // Mode picker
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

                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10)
                            ], spacing: 10) {
                                ForEach(visibleModes, id: \.self) { mode in
                                    chargingModeCell(mode: mode)
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

    // MARK: - Mode Cell (2-column grid)

    @ViewBuilder
    private func chargingModeCell(mode: ChargingMode) -> some View {
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
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(accentColor.opacity(isSelected ? 0.2 : 0.08))
                        .frame(width: 36, height: 36)
                    modeIcon(for: mode)
                        .font(.system(size: 16))
                        .foregroundStyle(accentColor)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(accentColor)
                            .background(Circle().fill(.white).frame(width: 10, height: 10))
                            .offset(x: 14, y: -14)
                    }
                }

                ChargingModelLabelView(chargingMode: mode)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
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
            .overlay(alignment: .topTrailing) {
                ChargingModeInfoButton(description: modeDescription(for: mode))
                    .padding(6)
            }
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

    // MARK: - Car Card

    @ViewBuilder
    private func carCard(car: Car) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "car.side")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Text(car.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
            }

            HStack(spacing: 12) {
                if let batteryPercent = car.batteryPercent {
                    HStack(spacing: 4) {
                        Image(systemName: batteryIconName(percent: batteryPercent))
                            .font(.caption)
                        Text(String(format: "%.0f%%", batteryPercent))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.secondary)
                }

                if let distance = car.remainingDistance {
                    HStack(spacing: 4) {
                        Image(systemName: "road.lanes")
                            .font(.caption)
                        Text("\(distance) km")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.blue.opacity(colorScheme == .dark ? 0.10 : 0.06))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
        )
    }

    private func batteryIconName(percent: Double) -> String {
        if percent > 95 { return "battery.100percent" }
        if percent > 70 { return "battery.75percent" }
        if percent > 45 { return "battery.50percent" }
        if percent > 20 { return "battery.25percent" }
        return "battery.0percent"
    }

    private func modeColor(for mode: ChargingMode) -> Color {
        switch mode {
        case .withSolarPower: Color(red: 0.95, green: 0.75, blue: 0.0)
        case .withSolarOrLowTariff: Color(red: 0.93, green: 0.5, blue: 0.0)
        case .alwaysCharge: Color(red: 0.0, green: 0.65, blue: 0.7)
        case .off: Color(red: 0.9, green: 0.2, blue: 0.15)
        case .constantCurrent: Color(red: 0.15, green: 0.7, blue: 0.25)
        case .minimalAndSolar: Color(red: 0.95, green: 0.75, blue: 0.0)
        case .minimumQuantity: Color(red: 0.2, green: 0.45, blue: 0.9)
        case .chargingTargetSoc: Color(red: 0.6, green: 0.3, blue: 0.85)
        }
    }

    private func modeDescription(for mode: ChargingMode) -> String {
        switch mode {
        case .withSolarPower:
            String(localized: "Charges your car only when enough solar power is available. Charging speed adjusts automatically based on current solar production.")
        case .withSolarOrLowTariff:
            String(localized: "Uses solar power during the day. If the car isn't fully charged by the low-tariff period, it charges at full speed during cheap electricity hours.")
        case .alwaysCharge:
            String(localized: "Charges at maximum power immediately, regardless of solar production or electricity tariff.")
        case .off:
            String(localized: "Charging is completely disabled. The car will not charge.")
        case .constantCurrent:
            String(localized: "Charges at a fixed power level that you choose, regardless of solar production.")
        case .minimalAndSolar:
            String(localized: "Always charges at a minimum rate to ensure some progress. Any extra solar power on top is used to charge faster.")
        case .minimumQuantity:
            String(localized: "Charges a specific amount of energy (kWh) by a deadline you set. Solar power is preferred when available.")
        case .chargingTargetSoc:
            String(localized: "Reaches a target battery percentage by a time you set. Prefers solar power when available and tops up from the grid if needed.")
        }
    }
}

private struct ChargingModeInfoButton: View {
    let description: String
    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Text("i")
                .font(.system(size: 13, weight: .bold, design: .serif))
                .foregroundStyle(.blue.opacity(0.5))
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isPresented, arrowEdge: .bottom) {
            VStack(alignment: .leading) {
                HStack(alignment: .firstTextBaseline) {
                    Image(systemName: "info.square.fill")
                    Text("Explanation")
                        .font(.headline)
                        .padding(.top, 4)
                }
                .foregroundColor(.blue)

                Text(description)
                    .padding(.top, 4)
                    .frame(width: 250)
            }
            .padding()
            .presentationCompactAdaptation(.popover)
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
