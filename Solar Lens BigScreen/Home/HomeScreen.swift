import SwiftUI

struct HomeScreen: View {
    @Environment(CurrentBuildingState.self) var buildings: CurrentBuildingState
    @State var refreshTimer: Timer?
    @State var solarForecastTimer: Timer?

    var body: some View {
        StandardLayout()
            .onAppear {
                startRefreshing()
            }
            .onDisappear() {
                stopRefreshing()
            }
    }

    private func startRefreshing() {
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

#Preview {
    HomeScreen()
        .environment(CurrentBuildingState.fake())
        .environment(UiContext())
}
