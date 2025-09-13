import SwiftUI

struct GridScreen: View {
    @Environment(CurrentBuildingState.self) var model: CurrentBuildingState
    @State var isLoading = false
    @State var energyManager: EnergyManager = SolarManager()
    @State var statisticsOverview: StatisticsOverview? = nil

    var body: some View {
        ZStack {

            LinearGradient(
                gradient: Gradient(colors: [
                    .indigo.opacity(0.4), .indigo.opacity(0.1),
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            GeometryReader { geometry in

                ScrollView {

                    VStack(alignment: .leading) {

                        Text("Today")
                            .font(.subheadline)


                        HStack {
                            EfficiencyInfoView(
                                todaySelfConsumptionRate: model
                                    .overviewData
                                    .todaySelfConsumptionRate,
                                todayAutarchyDegree: model
                                    .overviewData
                                    .todayAutarchyDegree,
                                showLegend: true,
                                showTitle: false,
                                legendAtBottom: false
                            )
                            .frame(minWidth: 47, maxHeight: 47)

                            Spacer()
                        }

                        if statisticsOverview != nil {

                            VStack {

                                SelfConsumption(
                                    weekStatistics: statisticsOverview!.week,
                                    monthStatistics: statisticsOverview!.month,
                                    yearStatistics: statisticsOverview!.year,
                                    overallStatistics: statisticsOverview!.overall
                                )

                                AutarkyDetails(
                                    weekStatistics: statisticsOverview!.week,
                                    monthStatistics: statisticsOverview!.month,
                                    yearStatistics: statisticsOverview!.year,
                                    overallStatistics: statisticsOverview!.overall
                                )
                            }
                            .padding(.top, 12)

                        }  // :VStack
                    }

                }  // :ScrollView

            }  // :GeometryReader
            .padding(.horizontal)

            if isLoading {
                ProgressView()
                    .tint(.orange)
                    .padding()
                    .foregroundStyle(.orange)
                    .background(Color.black.opacity(0.7))
            }

        }  // :ZStack
        .onAppear {
            isLoading = true

            Task {
                await fetchData()
            }

            isLoading = false
        }
    }

    func fetchData() async {
        statisticsOverview = try? await energyManager.fetchStatisticsOverview()
    }
}

#Preview("Sunny day") {
    let dayConsumption = 19876.3
    let dayProduction = 42309.2
    let daySelfConsumption = 42309.2
    let selfCunsumptionRate = 100 / dayProduction * dayConsumption
    let autantchyDegree = 100.0

    let statistics = StatisticsOverview(
        week: Statistics(
            consumption: dayConsumption * 7,
            production: dayProduction * 7,
            selfConsumption: daySelfConsumption * 7,
            selfConsumptionRate: selfCunsumptionRate,
            autarchyDegree: autantchyDegree,
        ),
        month: Statistics(
            consumption: dayConsumption * 30,
            production: dayProduction * 30,
            selfConsumption: daySelfConsumption * 30,
            selfConsumptionRate: selfCunsumptionRate,
            autarchyDegree: autantchyDegree,
        ),
        year: Statistics(
            consumption: dayConsumption * 365,
            production: dayProduction * 365,
            selfConsumption: daySelfConsumption * 365,
            selfConsumptionRate: selfCunsumptionRate,
            autarchyDegree: autantchyDegree,
        ),
        overall: Statistics(
            consumption: dayConsumption * 600,
            production: dayProduction * 600,
            selfConsumption: daySelfConsumption * 600,
            selfConsumptionRate: selfCunsumptionRate,
            autarchyDegree: autantchyDegree,
        )
    )

    GridScreen(
        energyManager: FakeEnergyManager(),
        statisticsOverview: statistics
    )
    .environment(CurrentBuildingState.fake())
}
