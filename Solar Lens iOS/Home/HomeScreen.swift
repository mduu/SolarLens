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
    @State var presentOnboarding: Bool = AppSettings().showOnboarding

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

                                    HeaderView(onRefresh: { refreshAll() })
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

                                        UpdateTimeStampView(
                                            isStale: buildingState.overviewData
                                                .isStaleData,
                                            updateTimeStamp: buildingState
                                                .overviewData
                                                .lastSuccessServerFetch,
                                            isLoading: buildingState.isLoading,
                                            onRefresh: nil
                                        )
                                        .padding(.leading, 5)

                                    }  // :VStack
                                    .padding(.trailing)

                                    EnergyFlow()

                                    VStack(alignment: .trailing) {
                                        AppLogo()

                                        HStack {
                                            RefreshButton(
                                                onRefresh: { refreshAll() })
                                                .padding(.trailing)
                                            SettingsButton()
                                        }

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

                        if buildingState.error != nil
                            || buildingState.errorMessage ?? "" != ""
                        {
                            VStack(alignment: .leading) {
                                Text("Something went wrong...")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                
                                    ScrollView {
                                        
                                        Text("Error message:")
                                            .font(.headline)
                                        
                                        Text(buildingState.errorMessage ?? "")
                                            .multilineTextAlignment(.leading)
                                            .padding(.bottom)
                                        
                                        Text("Error:")
                                            .font(.headline)
                                        
                                        Text(String(describing: buildingState.error))
                                            .multilineTextAlignment(.leading)
                                        
                                    }

                            }
                            .padding()
                            .border(Color.red, width: 2)
                            .background(.white)
                            .foregroundColor(.red)
                            .frame(maxHeight: 600)
                        }

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
                    refreshAll()
                }
                .fullScreenCover(
                    isPresented: $presentOnboarding,
                    onDismiss: {
                        AppSettings().showOnboarding = false
                    }
                ) {
                    OnboardingsView()
                }

            }  // :GeometryReader

        }  // :VStack
        .ignoresSafeArea()
    }

    private func refreshAll() {
        fetchOverviewData()
        fetchSolarForecastData()
    }

    private func fetchAndStartRefreshTimerForOverviewData() {
        if getAgeOfData() > 30 {
            print("forced fetch: overview data")
            refreshAll()
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

    private func getAgeOfData() -> TimeInterval {
        let lastUpdate = buildingState.overviewData.lastSuccessServerFetch
        guard let lastUpdate else {
            return TimeInterval.infinity
        }

        return Date().timeIntervalSince(lastUpdate)
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
        solarDetailsData: nil,
        presentOnboarding: false
    )
    .environment(
        CurrentBuildingState.fake(
            overviewData: OverviewData.empty(),
            isLoading: true
        )
    )
}
