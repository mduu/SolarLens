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
    @State private var detailRouter = HomeDetailRouter()
    /// Width of the whole screen, detail pane included. The dashboard is
    /// chosen by this rather than by the width left beside an open pane, or
    /// opening the pane would swap the layout underneath it.
    @State private var screenLayout: LayoutWidth = .compact
    @State private var screenWidth: CGFloat = 0
    @State private var tabSelection = TabSelection.shared

    /// The sidebar takes a good 300 pt; anything less is rounding.
    private var sidebarIsVisible: Bool {
        tabSelection.windowWidth - screenWidth > 100
    }
    @State private var commands = AppCommands.shared

    var isPortrait: Bool { verticalSizeClass != .compact }

    var body: some View {
        ZStack {
            BackgroundView()
                .ignoresSafeArea()
                .extendedUnderSidebar()

            VStack {
                GeometryReader { rootGeometry in
                    ScrollView {

                        ZStack {

                            if screenLayout != .compact {
                                dashboardContent
                                    .frame(minHeight: rootGeometry.size.height)
                                    .environment(\.layoutWidth, screenLayout)
                            } else if isPortrait {
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
                    .onChange(of: commands.refreshRequest) {
                        refreshAll()
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
        .environment(detailRouter)
        .environment(\.sidebarIsVisible, sidebarIsVisible)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { newValue in
            screenWidth = newValue
        }
        // The pane floats over the dashboard rather than pushing it aside:
        // an inspector column would re-flow every tile the moment one of
        // them is tapped.
        .overlay(alignment: .trailing) {
            if detailRouter.isShowingDetail {
                HomeDetailPane(router: detailRouter)
                    .frame(width: 420)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.2), radius: 24, x: -6, y: 0)
                    // Without the sidebar the tab bar floats across the top
                    // and does not reserve room for itself; start below it,
                    // or it covers the pane's close button.
                    .padding(.top, sidebarIsVisible ? 12 : 64)
                    .padding(.bottom, 12)
                    .padding(.trailing, 12)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.snappy(duration: 0.28), value: detailRouter.isShowingDetail)
        .onGeometryChange(for: LayoutWidth.self) { proxy in
            LayoutWidth.from(width: proxy.size.width)
        } action: { newValue in
            screenLayout = newValue
            detailRouter.usesPane = newValue == .wide
            if newValue != .wide { detailRouter.close() }
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

    /// iPad and Mac: the dashboard. It brings its own header, so the loading
    /// states sit where the iPhone's portrait layout puts them.
    @ViewBuilder
    private var dashboardContent: some View {
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
            HomeDashboardLayout(
                showError: $showError,
                solarDetailsData: solarDetailsData,
                onRefresh: { refreshAll() }
            )
            // The tab bar floats over the top without reserving room; with
            // the sidebar open there is only the status bar to clear.
            .padding(.top, sidebarIsVisible ? 50 : 92)
            .frame(maxHeight: .infinity, alignment: .top)
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
