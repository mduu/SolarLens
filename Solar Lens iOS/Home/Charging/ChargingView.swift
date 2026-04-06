import SwiftUI

struct ChargingView: View {
    var isVertical: Bool = true
    var applyCardStyle: Bool = true

    @Environment(CurrentBuildingState.self) var buildingState: CurrentBuildingState

    var body: some View {
        Group {
            if isVertical {
                VStack(spacing: 8) {
                    chargingContent(isVertical: true)
                }
            } else {
                HStack(spacing: 8) {
                    chargingContent(isVertical: false)
                }
            }
        }
    }

    @ViewBuilder
    private func chargingContent(isVertical: Bool) -> some View {
        ForEach(buildingState.overviewData.chargingStations.sorted(by: { $0.priority < $1.priority })) { station in
            ChargingStationCard(station: station, applyCardStyle: applyCardStyle)
        }
    }
}

struct ChargingStationCard: View {
    var station: ChargingStation
    var applyCardStyle: Bool = true
    @State private var showChargingModeSelection = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: station.currentPower > 0 ? "ev.charger.fill" : "ev.charger")
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .symbolEffect(
                        .pulse.wholeSymbol,
                        options: .repeat(.continuous),
                        isActive: station.currentPower > 0
                    )

                chargingModeIcon(for: station.chargingMode)
                    .font(.system(size: 16))
                    .foregroundStyle(chargingModeColor(for: station.chargingMode))
                    .offset(x: 8, y: 6)
            }
            .frame(width: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(station.name)
                    .font(.caption)
                    .foregroundStyle(.primary)

                if station.currentPower > 0 {
                    Text(String(format: "%.1f kW", Double(station.currentPower) / 1000))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                } else {
                    Text("Idle")
                        .font(.subheadline)
                        .foregroundStyle(.primary.opacity(0.6))
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .if(applyCardStyle) { $0.cardStyle() }
        .onTapGesture {
            showChargingModeSelection = true
        }
        .sheet(isPresented: $showChargingModeSelection) {
            ChargingModePickerView()
                .presentationDetents([.large])
        }
    }

    private func chargingModeIcon(for mode: ChargingMode) -> Image {
        switch mode {
        case .withSolarPower: Image(systemName: "sun.max.fill")
        case .withSolarOrLowTariff: Image(systemName: "sunset.fill")
        case .alwaysCharge: Image(systemName: "24.circle.fill")
        case .off: Image(systemName: "poweroff")
        case .constantCurrent: Image(systemName: "glowplug")
        case .minimalAndSolar: Image(systemName: "fluid.batteryblock")
        case .minimumQuantity: Image(systemName: "minus.plus.and.fluid.batteryblock")
        case .chargingTargetSoc: Image(systemName: "bolt.car.fill")
        }
    }

    private func chargingModeColor(for mode: ChargingMode) -> Color {
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
}

#Preview("Vertical") {
    ChargingView()
        .padding()
        .environment(
            CurrentBuildingState.fake(
                overviewData: OverviewData.fake()))
}

#Preview("Horizontal") {
    ChargingView(isVertical: false)
        .padding()
        .environment(
            CurrentBuildingState.fake(
                overviewData: OverviewData.fake()))
}
