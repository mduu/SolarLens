import SwiftUI

struct HomeScreen: View {
    @Environment(CurrentBuildingState.self) var buildings: CurrentBuildingState

    @State private var refreshTimer: Timer?
    @State private var solarForecastTimer: Timer?

    @State private var showMenu: Bool = false

    var body: some View {
        ZStack {

            if showMenu {
                StandardLayout()
            } else {
                StandardLayout()
                    .focusable()
            }

            FooterView(
                isLoading: buildings.isLoading,
                lastUpdate: buildings.overviewData.lastSuccessServerFetch
            )

            if showMenu {
                MainMenu()
            }
        }
        .onAppear {
            startRefreshing()
        }
        .onDisappear {
            stopRefreshing()
        }
        .onTapGesture {
            print("remote tap - refresh all")
            refreshAll()
        }
        .onExitCommand {
            showMenu.toggle()
        }

    }

    private func startRefreshing() {
        refreshAll()

        fetchAndStartRefreshTimerForOverviewData()
        fetchAndStartRefreshTimerForSolarDetailData()
    }

    private func stopRefreshing() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        solarForecastTimer?.invalidate()
        solarForecastTimer = nil
    }

    private func refreshAll() {
        fetchOverviewData()
        fetchSolarDetailsData()
    }

    private func fetchAndStartRefreshTimerForOverviewData() {
        if getAgeOfData() > 30 {
            print("forced fetch: overview data")
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
            await buildings.fetchServerData()
        }
    }

    private func fetchSolarDetailsData() {
        Task { @MainActor in
            print("fetch solar details data")
            await buildings.fetchSolarDetails()
        }
    }

    private func fetchAndStartRefreshTimerForSolarDetailData() {
        if buildings.solarDetailsData == nil {
            print("fetch solarDetailsData on appear")
            fetchSolarDetailsData()
        }
        if solarForecastTimer == nil {
            solarForecastTimer = Timer.scheduledTimer(
                withTimeInterval: 300,
                repeats: true
            ) {
                _ in
                print("fetch solarDetailsData on timer")
                fetchSolarDetailsData()
            }
        }
    }

    private func getAgeOfData() -> TimeInterval {
        let lastUpdate = buildings.overviewData.lastSuccessServerFetch
        guard let lastUpdate else {
            return TimeInterval.infinity
        }

        return Date().timeIntervalSince(lastUpdate)
    }
}

#Preview("Standard") {
    HomeScreen()
        .environment(CurrentBuildingState.fake())
        .environment(UiContext())
}
