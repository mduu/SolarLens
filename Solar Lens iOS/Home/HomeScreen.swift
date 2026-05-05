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
    @State var loadingStartedAt: Date? = nil

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
                                portraitContent
                                    .frame(minHeight: rootGeometry.size.height)
                            } else {
                                landscapeContent
                                    .padding()
                                    .padding(.horizontal, 30)
                            }

                        }  // :ZStack

                    }
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
            .ignoresSafeArea(.container, edges: .top)
        }
    }

    // MARK: - Layout Selection

    @ViewBuilder
    private var loadingTimeoutView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("Loading took too long")
                .font(.headline)
            Button("Retry") {
                refreshAll()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    @ViewBuilder
    private var portraitContent: some View {
        if isLoadingTimedOut() {
            loadingTimeoutView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 65)
        } else if isLoading() {
            VStack {
                MainProgressView()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 65)
        } else {
            HomePortraitLayout(
                showError: $showError,
                solarDetailsData: solarDetailsData,
                onRefresh: { refreshAll() }
            )
            .animation(nil, value: buildingState.overviewData.currentSolarProduction)
            .animation(nil, value: buildingState.overviewData.currentOverallConsumption)
            .animation(nil, value: buildingState.overviewData.currentBatteryLevel)
            .animation(nil, value: buildingState.overviewData.currentGridToHouse)
            .animation(nil, value: buildingState.overviewData.lastSuccessServerFetch)
        }
    }

    @ViewBuilder
    private var landscapeContent: some View {
        if isLoadingTimedOut() {
            loadingTimeoutView
        } else if isLoading() {
            MainProgressView(isLandscape: true)
        } else {
            HomeLandscapeLayout(
                solarDetailsData: solarDetailsData,
                onRefresh: { refreshAll() }
            )
            .animation(nil, value: buildingState.overviewData.currentSolarProduction)
            .animation(nil, value: buildingState.overviewData.currentOverallConsumption)
            .animation(nil, value: buildingState.overviewData.currentBatteryLevel)
            .animation(nil, value: buildingState.overviewData.currentGridToHouse)
            .animation(nil, value: buildingState.overviewData.lastSuccessServerFetch)
        }
    }

    // MARK: - Data Management

    private func refreshAll() {
        loadingStartedAt = nil
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
            if buildingState.overviewData.lastSuccessServerFetch == nil && loadingStartedAt == nil {
                loadingStartedAt = Date()
            }
            await buildingState.fetchServerData()
            if buildingState.overviewData.lastSuccessServerFetch != nil {
                loadingStartedAt = nil
            }
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

    private func isLoadingTimedOut() -> Bool {
        guard let startedAt = loadingStartedAt,
              buildingState.overviewData.lastSuccessServerFetch == nil
        else { return false }
        return Date().timeIntervalSince(startedAt) > CurrentBuildingState.viewLoadingTimeoutSeconds
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
