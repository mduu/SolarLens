import SwiftUI

struct ChartView: View {
    @Environment(CurrentBuildingState.self) var buildingModel:
        CurrentBuildingState
    @AppStorage("showBatteryCharging") private
        var showBatteryCharging: Bool = false
    @AppStorage("showBatteryDischarging") private
        var showBatteryDischarging: Bool = false

    @State var viewModel = ChartViewModel()
    @State private var refreshTimer: Timer?

    var body: some View {
        ZStack {

            VStack {
                if viewModel.error == nil && viewModel.errorMessage == nil {

                    if viewModel.consumptionData != nil {

                        VStack {

                            HStack {
                                Button(action: {
                                    showBatteryCharging.toggle()
                                }) {
                                    Image(systemName: "battery.100percent.bolt")
                                        .font(.system(size: 14))
                                        .padding(4)

                                }
                                .buttonBorderShape(.circle)
                                .buttonStyle(.bordered)
                                .tint(showBatteryCharging ? .purple : .gray)

                                Button(action: {
                                    showBatteryDischarging.toggle()
                                }) {
                                    Image(systemName: "battery.75percent")
                                        .font(.system(size: 14))
                                        .padding(4)

                                }
                                .buttonBorderShape(.circle)
                                .buttonStyle(.bordered)
                                .tint(showBatteryDischarging ? .indigo : .gray)

                                Spacer()
                            }

                            OverviewChart(
                                consumption: viewModel.consumptionData!,
                                batteries: viewModel.batteryHistory ?? [],
                                showBatteryCharge: showBatteryCharging,
                                showBatteryDischange: showBatteryDischarging
                            )

                            HStack {
                                let solarPeak = getMaxProductionkW()
                                TodaySolarView(
                                    peakProductionInW: solarPeak,
                                    currentSolarProductionInW: buildingModel
                                        .overviewData.currentSolarProduction,
                                    todaySolarProductionInWh: buildingModel
                                        .overviewData.todayProduction ?? 0
                                )
                                .frame(maxHeight: 115)

                                let consumptionPeak = getMaxConsumptionkW()
                                TodayConsumptionView(
                                    peakConsumptionInW: consumptionPeak,
                                    currentConsumptionInW: buildingModel
                                        .overviewData.currentOverallConsumption,
                                    todayConsumptionInWh: buildingModel
                                        .overviewData.todayConsumption ?? 0
                                )
                                .frame(maxHeight: 115)
                            }
                            .padding(.top)

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
            .map { Double($0.productionWatts) / 1000 }
            .max()

        guard let maxProduction else { return 0 }

        return maxProduction
    }

    private func getMaxConsumptionkW() -> Double {
        guard let consumptionData = viewModel.consumptionData else { return 0 }
        guard consumptionData.data.isEmpty == false else { return 0 }

        let maxConsumption: Double? = consumptionData.data
            .map { Double($0.consumptionWatts) / 1000 }
            .max()

        guard let maxConsumption else { return 0 }

        return maxConsumption
    }
}

#Preview {
    ChartView(
        viewModel: ChartViewModel.previewFake()
    )
    .frame(maxHeight: 350)
    .environment(
        CurrentBuildingState.fake(
            overviewData: OverviewData.fake()
        )
    )

}
