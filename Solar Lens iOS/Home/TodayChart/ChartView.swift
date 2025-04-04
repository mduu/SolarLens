import SwiftUI

struct ChartView: View {
    @Environment(CurrentBuildingState.self) var buildingModel:
        CurrentBuildingState
    @State var viewModel = ChartViewModel()
    @State private var refreshTimer: Timer?

    var body: some View {
        ZStack {

            VStack {
                if viewModel.error == nil && viewModel.errorMessage == nil {

                    if viewModel.consumptionData != nil {

                        VStack {

                            OverviewChart(
                                consumption: viewModel.consumptionData!
                            )

                            HStack {
                                Text(
                                    "\(Image(systemName: "sun.max")) Peak solar production ="
                                )
                                .font(.footnote)
                                Text(
                                    String(
                                        format: "%.2f kWp",
                                        getMaxProductionkW()
                                    )
                                )
                                .font(.footnote)
                                .foregroundColor(.yellow)
                            }
                            .padding(.top)

                            HStack {
                                Text("\(Image(systemName: "house")) Peak overall consumption =")
                                    .font(.footnote)
                                Text(
                                    String(
                                        format: "%.2f kWp",
                                        getMaxConsumptionkW()
                                    )
                                )
                                .font(.footnote)
                                .foregroundColor(.teal)
                            }

                            HStack {
                                let selfConsumptionPercentage =
                                    buildingModel.overviewData
                                    .todaySelfConsumptionRate ?? 0
                                
                                Text("Today self-consumption:")
                                    .font(.footnote)
                                Text(
                                    selfConsumptionPercentage
                                        .formatIntoPercentage()
                                )
                                .font(.footnote)
                                .foregroundColor(.indigo)
                            }
                            
                            HStack {
                                let autarky =
                                    buildingModel.overviewData
                                    .todayAutarchyDegree ?? 0
                                
                                Text("Today autarky:")
                                    .font(.footnote)
                                Text(
                                    autarky
                                        .formatIntoPercentage()
                                )
                                .font(.footnote)
                                .foregroundColor(.purple)
                            }

                        }

                    } else {

                        Spacer()
                        Text("No data")
                            .font(.footnote)
                        Spacer()

                    }

                }  // :if
            }  // :VStack
            .padding(8)
            .ignoresSafeArea(edges: .horizontal.union(.bottom))

            if viewModel.isLoading {
                ProgressView()
                    .tint(.accent)
                    .frame(width: 50, height: 50)
                    .padding()
            }
        }  // :ZStack
        .onAppear {
            Task {
                await viewModel.fetch()

                if refreshTimer == nil {
                    refreshTimer = Timer.scheduledTimer(
                        withTimeInterval: 300,
                        repeats: true
                    ) {
                        _ in
                        Task {
                            await viewModel.fetch()
                        }
                    }  // :refreshTimer
                }  // :if
            }  // :Task
        }  // :onAppear
        .onDisappear {
            if refreshTimer != nil {
                refreshTimer?.invalidate()
                refreshTimer = nil
            }
        }  // :onDisappear
    }

    private func getMaxProductionkW() -> Double {
        guard let consumptionData = viewModel.consumptionData else { return 0 }
        guard consumptionData.data.isEmpty == false else { return 0 }

        let maxProduction: Double? = consumptionData.data
            .map { $0.productionWatts / 1000 }
            .max()

        guard let maxProduction else { return 0 }

        return maxProduction
    }

    private func getMaxConsumptionkW() -> Double {
        guard let consumptionData = viewModel.consumptionData else { return 0 }
        guard consumptionData.data.isEmpty == false else { return 0 }

        let maxConsumption: Double? = consumptionData.data
            .map { $0.consumptionWatts / 1000 }
            .max()

        guard let maxConsumption else { return 0 }

        return maxConsumption
    }
}

#Preview {
    ChartView(
        viewModel: ChartViewModel.previewFake()
    )
    .frame(maxHeight: 400)
    .environment(
        CurrentBuildingState.fake(overviewData: OverviewData())
    )
    .environment(
        CurrentBuildingState.fake(
            overviewData: OverviewData.fake()
        )
    )

}
