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
            Image(systemName: station.currentPower > 0 ? "ev.charger.fill" : "ev.charger")
                .font(.title3)
                .foregroundStyle(.blue)
                .symbolEffect(
                    .pulse.wholeSymbol,
                    options: .repeat(.continuous),
                    isActive: station.currentPower > 0
                )
                .frame(width: 28)

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
            ChargingModePickerView(station: station)
                .presentationDetents([.large])
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
