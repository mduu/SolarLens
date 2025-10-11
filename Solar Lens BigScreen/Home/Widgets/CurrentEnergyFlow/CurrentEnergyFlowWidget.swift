import SwiftUI

struct CurrentEnergyFlowWidget: View {
    @Environment(CurrentBuildingState.self) var buildings: CurrentBuildingState

    var body: some View {
        VStack {
            WidgetHeaderView(title: "Now")

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
            .frame(height: 350)
            .padding(.horizontal, 50)
        }
        .padding(20)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .glassEffect(.clear, in: .rect(cornerRadius: 30.0))

    }

}

#Preview {
    VStack(alignment: .leading) {

        HStack(alignment: .top) {
            CurrentEnergyFlowWidget()
        }
        .frame(width: 550, height: 400)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.blue.opacity(0.4))
    .environment(CurrentBuildingState.fake())

}
