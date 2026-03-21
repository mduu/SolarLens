import SwiftUI

struct ChartView: View {
    @Environment(CurrentBuildingState.self) var buildingModel: CurrentBuildingState
    @AppStorage("todayShowProduction") private var showProduction: Bool = true
    @AppStorage("todayShowConsumption") private var showConsumption: Bool = true
    @AppStorage("showBatteryCharging") private var showBatteryCharging: Bool = false
    @AppStorage("showBatteryDischarging") private var showBatteryDischarging: Bool = false
    @AppStorage("showBatteryPercentag") private var showBatteryPercentage: Bool = true

    @State var viewModel = ChartViewModel()
    @State private var refreshTimer: Timer?

    var body: some View {
        ZStack {

            VStack {
                if viewModel.error == nil && viewModel.errorMessage == nil {

                    if viewModel.consumptionData != nil {

                        VStack(spacing: 12) {
                            OverviewChart(
                                consumption: viewModel.consumptionData!,
                                batteries: viewModel.batteryHistory ?? [],
                                showProduction: showProduction,
                                showConsumption: showConsumption,
                                showBatteryCharge: showBatteryCharging,
                                showBatteryDischange: showBatteryDischarging,
                                showBatteryPercentage: showBatteryPercentage,
                                showLegend: false
                            )

                            // Series toggles (same style as analytics)
                            VStack(spacing: 4) {
                                HStack(spacing: 6) {
                                    SeriesToggle(label: "Production", color: .yellow, isOn: $showProduction)
                                    SeriesToggle(label: "Consumption", color: .teal, isOn: $showConsumption)
                                }
                                HStack(spacing: 6) {
                                    SeriesToggle(label: "Battery %", color: SerieColors.batteryLevelColor(useAlternativeColors: false), isOn: $showBatteryPercentage)
                                    SeriesToggle(label: "Charged", color: .purple, isOn: $showBatteryCharging)
                                    SeriesToggle(label: "Discharged", color: .indigo, isOn: $showBatteryDischarging)
                                }
                            }

                            HStack(spacing: 12) {
                                let solarPeak = getMaxProductionkW()
                                TodaySolarView(
                                    peakProductionInW: solarPeak,
                                    currentSolarProductionInW: buildingModel
                                        .overviewData.currentSolarProduction,
                                    todaySolarProductionInWh: buildingModel
                                        .overviewData.todayProduction ?? 0
                                )

                                let consumptionPeak = getMaxConsumptionkW()
                                TodayConsumptionView(
                                    peakConsumptionInW: consumptionPeak,
                                    currentConsumptionInW: buildingModel
                                        .overviewData.currentOverallConsumption,
                                    todayConsumptionInWh: buildingModel
                                        .overviewData.todayConsumption ?? 0
                                )
                            }
                        }

                    } else {
                        Spacer()
                        Text("No data")
                            .font(.footnote)
                        Spacer()
                    }

                }
            }
            .padding(8)

            if viewModel.isLoading {
                ProgressView()
                    .tint(.accent)
                    .frame(width: 50, height: 50)
                    .padding()
            }
        }
        .onAppear {
            Task {
                await viewModel.fetch()

                if refreshTimer == nil {
                    refreshTimer = Timer.scheduledTimer(
                        withTimeInterval: 300,
                        repeats: true
                    ) { _ in
                        Task {
                            await viewModel.fetch()
                        }
                    }
                }
            }
        }
        .onDisappear {
            if refreshTimer != nil {
                refreshTimer?.invalidate()
                refreshTimer = nil
            }
        }
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
