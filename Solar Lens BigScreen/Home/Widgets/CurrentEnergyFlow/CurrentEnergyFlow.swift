import SwiftUI

struct CurrentEnergyFlow: View {
    @Environment(CurrentBuildingState.self) var buildings: CurrentBuildingState

    var body: some View {
        Grid {
            GridRow {
                SolarView(
                    currentSolarProductionInW: buildings.overviewData
                        .currentSolarProduction
                )
                .frame(maxWidth: .infinity)

                EmptyView()
                    .frame(maxWidth: .infinity)

                EmptyView()
                    .frame(maxWidth: .infinity)
            }

            GridRow {

                EmptyView()
                    .frame(maxWidth: .infinity)

                EmptyView()
                    .frame(maxWidth: .infinity)

                EmptyView()
                    .frame(maxWidth: .infinity)

            }

            GridRow {

                EmptyView()
                    .frame(maxWidth: .infinity)

                EmptyView()
                    .frame(maxWidth: .infinity)

                ConsumptionView(
                    currentOverallConsumptionInW: buildings.overviewData
                        .currentOverallConsumption
                )
                .frame(maxWidth: .infinity)

            }
        }
        .foregroundColor(.white.opacity(0.9))
        .padding(30)
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .glassEffect(in: .rect(cornerRadius: 30.0))

    }

}

#Preview {
    VStack {

        HStack {
            CurrentEnergyFlow()
        }
        .frame(maxWidth: .infinity)

    }
    .frame(maxHeight: .infinity)
    .background(.cyan.opacity(0.4))

}
