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
                buildingState.overviewData.isFlowGridToHouse()
                    ? buildingState.overviewData
                        .currentGridToHouse
                    : buildingState.overviewData
                        .currentSolarToGrid)
            / 1000

        Grid {

            GridRow {
                SolarBoubleView(
                    currentSolarProductionInKwh: solar,
                    todaySolarProductionInWh: buildingState
                        .overviewData.todayProduction
                )
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
                ArrowSolarToBattery(
                    isActive: buildingState.overviewData.isFlowSolarToBattery()
                )
                .frame(width: 50, height: 50)

                ArrowSolarToHouse(
                    isActive: buildingState.overviewData.isFlowSolarToHouse()
                )
                .frame(width: 50, height: 50)

                ArrowGridToHouse(
                    isActive: buildingState.overviewData.isFlowGridToHouse()
                )
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

                ArrowBatteryToHouse(
                    isActive: buildingState.overviewData.isFlowBatteryToHome()
                )
                .frame(width: 50, height: 50)

                ConsumptionBoubleView(
                    currentConsumptionInKwh: consumption,
                    todayConsumptionInWh: buildingState.overviewData
                        .todayConsumption
                )
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

#Preview("Large, To Grid") {
    EnergyFlow()
        .environment(
            CurrentBuildingState.fake(
                overviewData: .init(
                    currentSolarProduction: 4550,
                    currentOverallConsumption: 1000,
                    currentBatteryLevel: 100,
                    currentBatteryChargeRate: 0,
                    currentSolarToGrid: 2550,
                    currentGridToHouse: 0,
                    currentSolarToHouse: 1000,
                    solarProductionMax: 11000,
                    hasConnectionError: false,
                    lastUpdated: Date(),
                    lastSuccessServerFetch: Date(),
                    isAnyCarCharing: false,
                    chargingStations: [
                        .init(
                            id: "42",
                            name: "Keba 1",
                            chargingMode: ChargingMode.withSolarPower,
                            priority: 0,
                            currentPower: 0,
                            signal: SensorConnectionStatus.connected)
                    ],
                    devices: []
                )))

}

#Preview("Small") {
    EnergyFlow()
        .frame(maxWidth: 300, maxHeight: 300)
        .environment(
            CurrentBuildingState.fake(
                overviewData: OverviewData.fake()))

}
