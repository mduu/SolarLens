import SwiftUI

struct EnergyFlowView: View {
    @Environment(CurrentBuildingState.self) var buildingState:
        CurrentBuildingState
    @Environment(NavigationState.self) private var navigationState

    var body: some View {

        Grid {

            GridRow(alignment: .top) {
                SolarBoubleView(
                    currentSolarProduction: buildingState.overviewData
                        .currentSolarProduction,
                    maximumSolarProduction: buildingState.overviewData
                        .solarProductionMax
                )
                .frame(maxWidth: 50, maxHeight: 50)
                .onTapGesture {
                    navigationState.navigate(to: .solarProduction)
                }

                ArrowSolarToGrid(
                    isActive: buildingState.overviewData
                        .isFlowSolarToGrid()
                )
                .frame(maxWidth: 30, maxHeight: 30)

                GridBoubleView(
                    currentNetworkConsumption: buildingState.overviewData
                        .currentGridToHouse,
                    currentNetworkFeedin: buildingState.overviewData
                        .currentSolarToGrid,
                    isFlowFromNetwork: buildingState.overviewData
                        .isFlowGridToHouse(),
                    isFlowToNetwork: buildingState.overviewData
                        .isFlowSolarToGrid()
                )
                .frame(maxWidth: 50, maxHeight: 50)
            }

            GridRow(alignment: .center) {
                ArrowSolarToBattery(
                    isActive: buildingState.overviewData.isFlowSolarToBattery()
                )

                ArrowSolarToHouse(
                    isActive: buildingState.overviewData.isFlowSolarToHouse()
                )

                ArrowGridToHouse(
                    isActive: buildingState.overviewData.isFlowGridToHouse()
                )
            }
            .modifier(
                ConditionalMinHeight(
                    minHeightSmallWatch: 30,
                    minHeightLargeWatch: 45
                )
            )

            GridRow(alignment: .top) {
                BatteryBoubleView(
                    currentBatteryLevel: buildingState.overviewData
                        .currentBatteryLevel,
                    currentChargeRate: buildingState.overviewData
                        .currentBatteryChargeRate
                )
                .frame(maxWidth: 50, maxHeight: 50)
                .onTapGesture {
                    navigationState.navigate(to: .battery)
                }

                ArrowBatteryToHouse(
                    isActive: buildingState.overviewData.isFlowBatteryToHome()
                )
                .frame(maxHeight: 30)

                ConsumptionBoubleView(
                    currentOverallConsumption: buildingState.overviewData
                        .currentOverallConsumption,
                    isAnyCarCharging: buildingState.overviewData
                        .isAnyCarCharing
                )
                .frame(maxWidth: 50, maxHeight: 50)
                .onTapGesture {
                    navigationState.navigate(to: .consumption)
                }
            }

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }
}

#Preview("Default") {
    EnergyFlowView()
        .environment(
            CurrentBuildingState.fake(
                overviewData: OverviewData.fake()
            )
        )
        .environment(NavigationState.init())
}

#Preview("Battery to house") {
    EnergyFlowView()
        .environment(
            CurrentBuildingState.fake(
                overviewData: OverviewData.fake(batteryToHouse: true)
            )
        )
        .environment(NavigationState.init())
}
