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

        Grid {

            GridRow {
                SolarBoubleView(solarInKwh: solar)
                    .frame(maxWidth: .infinity)

                ArrowSolarToGrid(
                    isActive: buildingState.overviewData
                        .isFlowSolarToGrid()
                )
                .frame(width: 50, height: 50)

                GridBoubleView(gridInKwh: grid)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity)

            GridRow {
                ArrowSolarToBattery(isActive: buildingState.overviewData.isFlowSolarToBattery())
                    .frame(width: 50, height: 50)

                ArrowSolarToHouse(isActive: buildingState.overviewData.isFlowSolarToHouse())
                    .frame(width: 50, height: 50)

                ArrowGridToHouse(isActive: buildingState.overviewData.isFlowGridToHouse())
                    .frame(width: 50, height: 50)
            }
            .frame(height: 50)

            GridRow {
                BatteryBoubleView(
                    currentBatteryLevel: buildingState
                        .overviewData
                        .currentBatteryLevel,
                    currentChargeRate: buildingState
                        .overviewData
                        .currentBatteryChargeRate
                )
                .frame(maxWidth: .infinity)

                ArrowBatteryToHouse(isActive: buildingState.overviewData.isFlowBatteryToHome())
                    .frame(width: 50, height: 50)

                ConsumptionBoubleView(totalConsumptionInKwh: consumption)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity)

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)

    }
}

#Preview("Large") {
    EnergyFlow()
        .environment(
            CurrentBuildingState.fake(
                overviewData: OverviewData.fake()))

}

#Preview("Small") {
    EnergyFlow()
        .frame(maxWidth: 250, maxHeight: 250)
        .environment(
            CurrentBuildingState.fake(
                overviewData: OverviewData.fake()))

}
