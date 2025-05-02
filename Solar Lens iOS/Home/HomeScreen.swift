import SwiftUI

struct HomeScreen: View {
    @Environment(CurrentBuildingState.self) var buildingState:
        CurrentBuildingState
    @Environment(\.energyManager) var energyManager
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @State var refreshTimer: Timer?
    @State var solarForecastTimer: Timer?
    @State var solarDetailsData: SolarDetailsData?
    @State var appSettings: AppSettings = AppSettings()

    var isPortrait: Bool { verticalSizeClass != .compact }

    var body: some View {
        VStack {
            GeometryReader { rootGeometry in

                ScrollView {

                    ZStack {

                        BackgroundView()

                        if isPortrait {
                            VStack {
                                if isLoading() {
                                    MainProgressView()
                                        .padding(.top, 65)
                                } else {

                                    HeaderView()
                                        .padding(.top, 65)

                                    Spacer()

                                    HStack(alignment: .bottom) {
                                        if solarDetailsData != nil {
                                            SolarForecastView(
                                                solarProductionMax:
                                                    buildingState
                                                    .overviewData
                                                    .solarProductionMax,
                                                todaySolarProduction:
                                                    solarDetailsData!
                                                    .todaySolarProduction,
                                                forecastToday: solarDetailsData!
                                                    .forecastToday,
                                                forecastTomorrow:
                                                    solarDetailsData!
                                                    .forecastTomorrow,
                                                forecastDayAfterTomorrow:
                                                    solarDetailsData!
                                                    .forecastDayAfterTomorrow
                                            )
                                            .frame(
                                                maxWidth: 180,
                                                maxHeight: 120
                                            )
                                            .padding(.leading, 5)
                                        } else {
                                            ProgressView()
                                                .frame(
                                                    maxWidth: 180,
                                                    maxHeight: 120
                                                )
                                                .padding(.leading, 5)
                                        }

                                        EfficiencyInfoView(
                                            todaySelfConsumptionRate:
                                                buildingState
                                                .overviewData
                                                .todaySelfConsumptionRate,
                                            todayAutarchyDegree: buildingState
                                                .overviewData
                                                .todayAutarchyDegree
                                        )
                                        .frame(maxWidth: 180, maxHeight: 120)
                                        .padding(.leading, 5)

                                    }  // :HStack
                                    .padding()

                                    EnergyFlow()
                                        .padding(.horizontal, 50)

                                    HStack(alignment: .bottom) {
                                        Spacer()

                                        ChargingView(
                                            isVertical: true
                                        )

                                    }  // :HStack
                                    .padding()

                                    Spacer()

                                    FooterView()

                                }

                            }  // :VStack
                            .frame(height: rootGeometry.size.height)

                        } else {
                            HStack {

                                if isLoading() {
                                    MainProgressView(isLandscape: true)
                                } else {

                                    VStack {

                                        if solarDetailsData != nil {
                                            SolarForecastView(
                                                solarProductionMax:
                                                    buildingState
                                                    .overviewData
                                                    .solarProductionMax,
                                                todaySolarProduction:
                                                    solarDetailsData!
                                                    .todaySolarProduction,
                                                forecastToday: solarDetailsData!
                                                    .forecastToday,
                                                forecastTomorrow:
                                                    solarDetailsData!
                                                    .forecastTomorrow,
                                                forecastDayAfterTomorrow:
                                                    solarDetailsData!
                                                    .forecastDayAfterTomorrow
                                            )
                                            .frame(
                                                maxWidth: 180,
                                                maxHeight: 120
                                            )
                                            .padding(.leading, 5)
                                        } else {
                                            ProgressView()
                                                .frame(
                                                    maxWidth: 180,
                                                    maxHeight: 120
                                                )
                                                .padding(.leading, 5)
                                        }

                                        Spacer()

                                        EfficiencyInfoView(
                                            todaySelfConsumptionRate:
                                                buildingState
                                                .overviewData
                                                .todaySelfConsumptionRate,
                                            todayAutarchyDegree: buildingState
                                                .overviewData
                                                .todayAutarchyDegree
                                        )
                                        .frame(maxWidth: 180, maxHeight: 120)
                                        .padding(.leading, 5)
                                    }  // :VStack
                                    .padding(.trailing)

                                    EnergyFlow()

                                    VStack(alignment: .trailing) {
                                        AppLogo()

                                        SettingsButton()

                                        Spacer()

                                        ChargingView(
                                            isVertical: false
                                        )
                                    }  // :VStack

                                }

                            }  // :HStack
                            .padding()
                            .padding(.horizontal, 30)
                        }  // :else

                    }  // :ZStack
                    .frame(maxHeight: rootGeometry.size.height)

                }
                .frame(maxHeight: rootGeometry.size.height)
                .onAppear {
                    fetchAndStartRefreshTimerForOverviewData()
                    fetchAndStartRefreshTimerForSolarDetailData()
                }
                .refreshable {
                    print("fetch on pull to refresh: overview data")
                    fetchOverviewData()
                    fetchSolarForecastData()
                }
                .fullScreenCover(
                    isPresented: appSettings.needToShowOnboarding
                ) {
                    OnboardingsView()
                }

            }  // :GeometryReader

        }  // :VStack
        .ignoresSafeArea()
    }

    private func fetchAndStartRefreshTimerForOverviewData() {
        if buildingState.overviewData.lastSuccessServerFetch == nil {
            print("initial fetch overview data")
            fetchOverviewData()
        }

        if refreshTimer == nil {
            refreshTimer = Timer.scheduledTimer(
                withTimeInterval: 15,
                repeats: true
            ) {
                _ in
                print("fetch on timer: overview data")
                fetchOverviewData()
            }
        }
    }

    private func fetchOverviewData() {
        Task { @MainActor in
            print("fetch overview data")
            await buildingState.fetchServerData()
        }
    }

    private func fetchAndStartRefreshTimerForSolarDetailData() {
        if solarDetailsData == nil {
            print("fetch solarDetailsData on appear")
            fetchSolarForecastData()
        }
        if solarForecastTimer == nil {
            solarForecastTimer = Timer.scheduledTimer(
                withTimeInterval: 300,
                repeats: true
            ) {
                _ in
                print("fetch solarDetailsData on timer")
                fetchSolarForecastData()
            }
        }
    }

    private func fetchSolarForecastData() {
        Task { @MainActor in
            print("fetch solarDetailsData")
            solarDetailsData =
                try await energyManager.fetchSolarDetails()
        }
    }

    private func isLoading() -> Bool {
        buildingState.isLoading
            && buildingState.overviewData.lastSuccessServerFetch == nil
    }
}

#Preview("Normal") {
    HomeScreen(
        solarDetailsData: SolarDetailsData.fake()
    )
    .environment(
        CurrentBuildingState.fake(
            overviewData: OverviewData.fake()
        )
    )
}

#Preview("Loading") {
    HomeScreen(
        solarDetailsData: nil
    )
    .environment(
        CurrentBuildingState.fake(
            overviewData: OverviewData.empty(),
            isLoading: true
        )
    )
}
