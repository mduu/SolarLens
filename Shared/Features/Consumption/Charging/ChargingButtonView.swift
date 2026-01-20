import SwiftUI

struct ChargingButtonView: View {
    var chargingMode: ChargingMode
    var chargingStation: ChargingStation
    var largeButton: Bool = false

    @Environment(CurrentBuildingState.self) var model: CurrentBuildingState
    @State private var showingPopup = false

    var body: some View {
        Button(action: {
            print("\(chargingMode) pressed")

            if chargingMode.isSimpleChargingMode() {
                Task {
                    await setSimpleChargingMode(
                        chargingStation: chargingStation,
                        chargingMode: chargingMode)
                }
            } else {
                showingPopup = true
            }

        }) {
            HStack(spacing: 2) {
                getModeImage(for: chargingMode)
                    .padding(.leading, 3)

                ChargingModelLabelView(chargingMode: chargingMode)

                Spacer(minLength: 0)
            }
            .frame(alignment: .leading)
            .padding(.all, 0)
        }
        .buttonStyle(.automatic)
        .frame(maxWidth: .infinity)
        .padding(.all, largeButton ? 5 : 0)
        .background(
            getBackgroundColor(
                chargingMode: chargingMode,
                chargingStation: chargingStation)
        )
        .tint(
            getButtonTint(
                chargingMode: chargingMode,
                chargingStation: chargingStation)
        )
        .sheet(isPresented: $showingPopup) {
            ChargingOptionsPopupView(
                chargingMode: chargingMode,
                chargingStation: chargingStation
            )
            .presentationDetents([.height(300)])
        }
    }

    private func getModeImage(for mode: ChargingMode) -> some View {
        switch mode {
        case .withSolarPower:
            return getColoredImage(systemName: "sun.max", color: .yellow)
        case .withSolarOrLowTariff:
            return getColoredImage(systemName: "sunset", color: .orange)
        case .alwaysCharge:
            return getColoredImage(systemName: "24.circle", color: .teal)
        case .off:
            return getColoredImage(systemName: "poweroff", color: .red)
        case .constantCurrent:
            return getColoredImage(systemName: "glowplug", color: .green)
        case .minimalAndSolar:
            return getColoredImage(
                systemName: "fluid.batteryblock", color: .yellow)
        case .minimumQuantity:
            return getColoredImage(
                systemName: "minus.plus.and.fluid.batteryblock", color: .blue)
        case .chargingTargetSoc:
            return getColoredImage(systemName: "bolt.car", color: .purple)
        }
    }

    private func getColoredImage(systemName: String, color: Color = .primary)
        -> some View
    {
        return Image(systemName: systemName)
            .foregroundColor(color)
    }

    private func getButtonTint(
        chargingMode: ChargingMode,
        chargingStation: ChargingStation
    ) -> Color? {
        return (chargingStation.chargingMode == chargingMode) && !largeButton
            ? .accent
            : .primary
    }

    private func getBackgroundColor(
        chargingMode: ChargingMode,
        chargingStation: ChargingStation
    ) -> Color? {
        return (chargingStation.chargingMode == chargingMode) && largeButton
            ? .accent.opacity(0.3)
            : .clear
    }

    private func setSimpleChargingMode(
        chargingStation: ChargingStation,
        chargingMode: ChargingMode
    ) async {
        guard chargingMode.isSimpleChargingMode() else {
            print("ERROR: \(chargingMode) is not a simple charging mode")
            return
        }

        await model.setCarCharging(
            sensorId: chargingStation.id,
            newCarCharging:
                ControlCarChargingRequest.init(chargingMode: chargingMode))
    }

}

#Preview("Selected") {
    ChargingButtonView(
        chargingMode: .withSolarPower,
        chargingStation: ChargingStation(
            id: "2134",
            name: "Station 2",
            chargingMode: .withSolarPower,
            priority: 1,
            currentPower: 0,
            signal: .connected
        )
    )
    .environment(CurrentBuildingState.fake(overviewData: OverviewData.fake()))
}

#Preview("Selected iOS") {
    ChargingButtonView(
        chargingMode: .withSolarPower,
        chargingStation: ChargingStation(
            id: "2134",
            name: "Station 2",
            chargingMode: .withSolarPower,
            priority: 1,
            currentPower: 0,
            signal: .connected
        ),
        largeButton: true
    )
    .environment(CurrentBuildingState.fake(overviewData: OverviewData.fake()))
}

#Preview("Unselected") {
    ChargingButtonView(
        chargingMode: .off,
        chargingStation: ChargingStation(
            id: "2134",
            name: "Station 2",
            chargingMode: .withSolarPower,
            priority: 1,
            currentPower: 0,
            signal: .connected
        )

    )
    .environment(CurrentBuildingState.fake(overviewData: OverviewData.fake()))
}
