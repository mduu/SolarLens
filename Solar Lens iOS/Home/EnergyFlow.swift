import SwiftUI

struct EnergyFlow: View {
    @Environment(CurrentBuildingState.self) var buildingState:
        CurrentBuildingState

    var body: some View {
        let solar =
            Double(
                buildingState.overviewData
                    .currentSolarProduction)
            / 1000

        let consumption =
            Double(
                buildingState.overviewData
                    .currentOverallConsumption)
            / 1000

        let grid =
            Double(
                buildingState.overviewData.currentGridToHouse
                    >= 0
                    ? buildingState.overviewData
                        .currentGridToHouse
                    : buildingState.overviewData
                        .currentSolarToGrid)
            / 1000
        
        Grid(horizontalSpacing: 2, verticalSpacing: 20) {

            GridRow(alignment: .center) {
                CircularInstrument(
                    borderColor: Color.accentColor,
                    label: "Solar Production",
                    value: String(format: "%.1f kW", solar)
                ) {
                    Image(systemName: "sun.max")
                        .foregroundColor(.black)
                }
                .frame(maxWidth: 120, maxHeight: 120)

                if buildingState.overviewData
                    .isFlowSolarToGrid()
                {
                    Image(systemName: "arrow.right")
                        .foregroundColor(.orange)
                        .font(
                            .system(
                                size: 50, weight: .light)
                        )
                        .symbolEffect(
                            .wiggle.byLayer,
                            options: .repeat(
                                .periodic(delay: 0.7)))
                } else {
                    Text("")
                        .frame(minWidth: 50, minHeight: 50)
                }

                CircularInstrument(
                    borderColor: Color.orange,
                    label: "Grid",
                    value: String(format: "%.1f kW", grid)
                ) {
                    Image(systemName: "network")
                        .foregroundColor(.black)
                }
                .frame(maxWidth: 120, maxHeight: 120)
            }  // :GridRow

            GridRow(alignment: .center) {
                if buildingState.overviewData
                    .isFlowSolarToBattery()
                {
                    Image(systemName: "arrow.down")
                        .foregroundColor(.green)
                        .font(
                            .system(
                                size: 50, weight: .light)
                        )
                        .symbolEffect(
                            .wiggle.byLayer,
                            options: .repeat(
                                .periodic(delay: 0.7)))

                } else {
                    Text("")
                        .frame(minWidth: 50, minHeight: 50)
                }

                if buildingState.overviewData
                    .isFlowSolarToHouse()
                {
                    Image(systemName: "arrow.down.right")
                        .foregroundColor(.green)
                        .font(
                            .system(
                                size: 50, weight: .light)
                        )
                        .symbolEffect(
                            .wiggle.byLayer,
                            options: .repeat(
                                .periodic(delay: 0.7)))
                } else {
                    Text("")
                        .frame(minWidth: 50, minHeight: 50)
                }

                if buildingState.overviewData
                    .isFlowGridToHouse()
                {
                    Image(systemName: "arrow.down")
                        .foregroundColor(.orange)
                        .font(
                            .system(
                                size: 50, weight: .light)
                        )
                        .symbolEffect(
                            .wiggle.byLayer,
                            options: .repeat(
                                .periodic(delay: 0.7)))
                } else {
                    Text("")
                        .frame(minWidth: 50, minHeight: 50)
                }
            }  // :GridRow
            .frame(minWidth: 30, minHeight: 20)

            GridRow(alignment: .center) {
                if buildingState.overviewData
                    .currentBatteryLevel != nil
                {
                    BatteryBoubleView(
                        currentBatteryLevel: buildingState
                            .overviewData
                            .currentBatteryLevel,
                        currentChargeRate: buildingState
                            .overviewData
                            .currentBatteryChargeRate
                    )
                } else {
                    Text("")
                        .frame(
                            minWidth: 120, minHeight: 120)
                }

                if buildingState.overviewData
                    .isFlowBatteryToHome()
                {
                    Image(systemName: "arrow.right")
                        .foregroundColor(.green)
                        .font(
                            .system(
                                size: 50, weight: .light)
                        )
                        .symbolEffect(
                            .wiggle.byLayer,
                            options: .repeat(
                                .periodic(delay: 0.7)))
                } else {
                    Text("")
                        .frame(minWidth: 50, minHeight: 50)
                }

                CircularInstrument(
                    borderColor: Color.teal,
                    label: "Consumption",
                    value: String(
                        format: "%.1f kW", consumption)
                ) {
                    Image(systemName: "house")
                        .foregroundColor(.black)
                }
                .frame(maxWidth: 120, maxHeight: 120)
            }  // :GridRow

        }  // :Grid
    }
}

#Preview {
    EnergyFlow()
        .environment(
            CurrentBuildingState.fake(
                overviewData: OverviewData.fake()))

}
