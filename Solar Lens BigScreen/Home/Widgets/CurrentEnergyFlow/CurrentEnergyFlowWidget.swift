import SwiftUI

struct CurrentEnergyFlowWidget: View {
    @Environment(CurrentBuildingState.self) var buildings: CurrentBuildingState

    var body: some View {
        Grid {
            GridRow {
                SolarView(
                    currentSolarProductionInW: buildings.overviewData
                        .currentSolarProduction
                )
                .frame(maxWidth: .infinity)

                ArrowSolarToGrid(
                    isActive: buildings.overviewData.isFlowSolarToGrid()
                )
                .frame(maxWidth: .infinity)

                CurrentGridView(
                    currentGridInW:
                        buildings.overviewData.isFlowSolarToGrid()
                        ? buildings.overviewData.currentSolarToGrid
                        : buildings.overviewData.currentGridToHouse
                )
                .frame(maxWidth: .infinity)
            }

            GridRow {

                ArrowSolarToBattery(
                    isActive: buildings.overviewData.isFlowSolarToBattery()
                )
                .frame(maxWidth: .infinity)

                ArrowSolarToHouse(
                    isActive: buildings.overviewData.isFlowSolarToHouse()
                )
                .frame(maxWidth: .infinity)

                ArrowGridToHouse(
                    isActive: buildings.overviewData.isFlowGridToHouse()
                )
                .frame(maxWidth: .infinity)

            }

            GridRow {

                CurrentBatteryView(
                    currentBatteryLevel: buildings.overviewData
                        .currentBatteryLevel,
                    currentChargeRate: buildings.overviewData
                        .currentBatteryChargeRate
                )
                .frame(maxWidth: .infinity)

                ArrowBatteryToHouse(
                    isActive: buildings.overviewData.isFlowBatteryToHome()
                )
                .frame(maxWidth: .infinity)

                ConsumptionView(
                    currentOverallConsumptionInW: buildings.overviewData
                        .currentOverallConsumption
                )
                .frame(maxWidth: .infinity)

            }
        }
        .foregroundColor(.white.opacity(0.9))
        .padding(50)
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .glassEffect(in: .rect(cornerRadius: 30.0))

    }

}

#Preview {
    VStack {

        HStack {
            CurrentEnergyFlowWidget()
        }
        .frame(maxWidth: .infinity)

    }
    .frame(maxHeight: .infinity)
    .background(.cyan.opacity(0.4))

}
