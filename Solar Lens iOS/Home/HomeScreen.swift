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
    @State var showError: Bool = false

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
                            VStack {
                                Spacer()

                                HStack {
                                    Button(action: {
                                        showError = true
                                    }) {
                                        Image(
                                            systemName:
                                                "exclamationmark.bubble.fill"
                                        )
                                        .font(.system(size: 32))
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundColor(.red)

                                    Spacer()
                                }
                                .padding(.leading, 20)
                                .padding(.bottom, 50)
                                .sheet(
                                    isPresented: $showError
                                ) {
                                    NavigationView {

                                        ScrollView(showsIndicators: true) {

                                            VStack(alignment: .leading) {

                                                Text("Error message:")
                                                    .frame(
                                                        maxWidth: .infinity,
                                                        alignment: .leading
                                                    )
                                                    .font(.title2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.red)

                                                Text(
                                                    buildingState.errorMessage
                                                        ?? "-"
                                                )
                                                .multilineTextAlignment(
                                                    .leading
                                                )
                                                .frame(
                                                    maxWidth: .infinity,
                                                    alignment: .leading
                                                )

                                                Text("Error:")
                                                    .font(.title2)
                                                    .fontWeight(.bold)
                                                    .frame(
                                                        maxWidth: .infinity,
                                                        alignment: .leading
                                                    )
                                                    .foregroundColor(.red)

                                                Text(
                                                    String(
                                                        describing:
                                                            buildingState
                                                            .error
                                                    )
                                                )
                                                .multilineTextAlignment(
                                                    .leading
                                                )
                                                .frame(
                                                    maxWidth: .infinity,
                                                    alignment: .leading
                                                )

                                            }
                                            .frame(maxWidth: .infinity)
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .navigationBarTitleDisplayMode(.inline)
                                        .toolbar {
                                            ToolbarItem(
                                                placement: .navigationBarLeading
                                            ) {
                                                Button(action: {
                                                    showError = false
                                                }) {
                                                    Image(systemName: "xmark")  // Use a system icon
                                                        .resizable()  // Make the image resizable
                                                        .scaledToFit()  // Fit the image within the available space
                                                        .frame(
                                                            width: 18,
                                                            height: 18
                                                        )  // Set the size of the image
                                                        .foregroundColor(.red)  // Set the color of the image
                                                }

                                            }
                                            ToolbarItem(
                                                placement:
                                                    .navigationBarTrailing
                                            ) {
                                                Text("Error")
                                                    .foregroundColor(.red)
                                            }
                                        }
                                    }

                                }
                            }
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
        .ignoresSafeArea(.all, edges: [.leading, .trailing, .top])
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
