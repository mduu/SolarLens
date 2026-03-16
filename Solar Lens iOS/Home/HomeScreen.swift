import SwiftUI

struct HomeScreen: View {
    @Environment(CurrentBuildingState.self) var buildingState: CurrentBuildingState
    @Environment(\.energyManager) var energyManager
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @State var refreshTimer: Timer?
    @State var solarForecastTimer: Timer?
    @State var solarDetailsData: SolarDetailsData?
    @State var presentOnboarding: Bool = AppSettings().showOnboarding
    @State var showError: Bool = false
    // Survey Logic
    @State var showSurvey: Bool = false
    @AppStorage("surveyForeverDismissed") var surveyForeverDismissed: Bool = false
    @AppStorage("surveyLastShownDate") var surveyLastShownDate: Double = 0.0

    var isPortrait: Bool { verticalSizeClass != .compact }

    var body: some View {
        ZStack {
            BackgroundView()
                .ignoresSafeArea()

            VStack {
                GeometryReader { rootGeometry in

                    ScrollView {

                        ZStack {

                            if isPortrait {
                                portraitLayout
                                    .frame(minHeight: rootGeometry.size.height)
                                    .animation(nil, value: buildingState.overviewData.currentSolarProduction)
                                    .animation(nil, value: buildingState.overviewData.currentOverallConsumption)
                                    .animation(nil, value: buildingState.overviewData.currentBatteryLevel)
                                    .animation(nil, value: buildingState.overviewData.currentGridToHouse)
                                    .animation(nil, value: buildingState.overviewData.lastSuccessServerFetch)
                            } else {
                                landscapeLayout
                                    .frame(minHeight: rootGeometry.size.height)
                                    .animation(nil, value: buildingState.overviewData.currentSolarProduction)
                                    .animation(nil, value: buildingState.overviewData.currentOverallConsumption)
                                    .animation(nil, value: buildingState.overviewData.currentBatteryLevel)
                                    .animation(nil, value: buildingState.overviewData.currentGridToHouse)
                                    .animation(nil, value: buildingState.overviewData.lastSuccessServerFetch)
                                    .padding()
                                    .padding(.horizontal, 30)
                            }


                        }  // :ZStack

                    }
                    .onAppear {
                        fetchAndStartRefreshTimerForOverviewData()
                        fetchAndStartRefreshTimerForSolarDetailData()
                        checkSurveyDisplay()
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
            .ignoresSafeArea(.container, edges: .top)

            if showSurvey {
                SurveyView(isPresented: $showSurvey.animation())
                    .zIndex(100)
            }
        }
    }

    // MARK: - Portrait Layout

    @ViewBuilder
    private var portraitLayout: some View {
        if isLoading() {
            VStack {
                MainProgressView()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 65)
        } else {
            VStack(spacing: 10) {
                HeaderView(onRefresh: { refreshAll() }, showError: $showError)
                    .padding(.top, 65)

                Spacer()

                // 2x2 Energy Flow Grid + Charging (vertically centered)
                EnergyFlowGrid(showCharging: true)
                    .padding(.horizontal, 16)

                Spacer()

                // Forecast & Efficiency cards (above footer)
                HStack(alignment: .bottom, spacing: 16) {
                    if solarDetailsData != nil {
                        SolarForecastView(
                            solarProductionMax: buildingState.overviewData.solarProductionMax,
                            todaySolarProduction: solarDetailsData!.todaySolarProduction,
                            forecastToday: solarDetailsData!.forecastToday,
                            forecastTomorrow: solarDetailsData!.forecastTomorrow,
                            forecastDayAfterTomorrow: solarDetailsData!.forecastDayAfterTomorrow
                        )

                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 160)
                    }

                    EfficiencyGaugeView(
                        todaySelfConsumptionRate: buildingState.overviewData.todaySelfConsumptionRate,
                        todayAutarchyDegree: buildingState.overviewData.todayAutarchyDegree
                    )
                    .cardStyle()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

                FooterView()
            }
            .transaction { transaction in
                transaction.animation = nil
            }
        }
    }

    // MARK: - Landscape Layout

    @ViewBuilder
    private var landscapeLayout: some View {
        if isLoading() {
            MainProgressView(isLandscape: true)
        } else {
            HStack(alignment: .center, spacing: 16) {
                // Left: Energy Flow Grid
                EnergyFlowGrid()

                // Right column: Forecast + Efficiency + Charging + Controls
                VStack(spacing: 8) {
                    if solarDetailsData != nil {
                        SolarForecastView(
                            solarProductionMax: buildingState.overviewData.solarProductionMax,
                            todaySolarProduction: solarDetailsData!.todaySolarProduction,
                            forecastToday: solarDetailsData!.forecastToday,
                            forecastTomorrow: solarDetailsData!.forecastTomorrow,
                            forecastDayAfterTomorrow: solarDetailsData!.forecastDayAfterTomorrow
                        )
                        .frame(maxWidth: 180, maxHeight: 120)
                    } else {
                        ProgressView()
                            .frame(maxWidth: 180, maxHeight: 120)
                    }

                    EfficiencyGaugeView(
                        todaySelfConsumptionRate: buildingState.overviewData.todaySelfConsumptionRate,
                        todayAutarchyDegree: buildingState.overviewData.todayAutarchyDegree
                    )
                    .frame(maxWidth: 180, maxHeight: 120)

                    if !buildingState.overviewData.chargingStations.isEmpty {
                        ChargingView(isVertical: true)
                            .frame(maxWidth: 180)
                    }

                    Spacer()

                    HStack {
                        AppLogo()
                        Spacer()
                        RefreshButton(onRefresh: { refreshAll() })
                        SettingsButton()
                    }
                    .frame(maxWidth: 180)

                    UpdateTimeStampView(
                        isStale: buildingState.overviewData.isStaleData,
                        updateTimeStamp: buildingState.overviewData.lastSuccessServerFetch,
                        isLoading: buildingState.isLoading,
                        onRefresh: nil
                    )
                }
            }
        }
    }


    // MARK: - Data Management

    private func checkSurveyDisplay() {
        let now = Date()
        var dateComponents = DateComponents()
        dateComponents.year = 2026
        dateComponents.month = 3
        dateComponents.day = 31

        guard let endDate = Calendar.current.date(from: dateComponents) else { return }

        if now > endDate { return }
        if surveyForeverDismissed { return }

        if surveyLastShownDate > 0 {
            let lastShown = Date(timeIntervalSince1970: surveyLastShownDate)
            if now.timeIntervalSince(lastShown) < 86400 {
                return
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if !presentOnboarding {
                showSurvey = true
            }
        }
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
            ) { _ in
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
            ) { _ in
                print("fetch solarDetailsData on timer")
                fetchSolarForecastData()
            }
        }
    }

    private func fetchSolarForecastData() {
        Task { @MainActor in
            print("fetch solarDetailsData")
            solarDetailsData = try await energyManager.fetchSolarDetails()
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
        solarDetailsData: SolarDetailsData.fake(),
        presentOnboarding: false
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

#Preview("Error") {
    HomeScreen(
        solarDetailsData: SolarDetailsData.fake(),
        presentOnboarding: false
    )
    .environment(
        CurrentBuildingState.fake(
            overviewData: OverviewData.fake(),
            error: .invalidData,
            errorMessage: "This is an error message!"
        )
    )
}
