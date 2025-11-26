import SwiftUI

struct HomeScreen: View {
    @Environment(CurrentBuildingState.self) var buildings: CurrentBuildingState

    @State private var refreshTimer: Timer?
    @State private var solarForecastTimer: Timer?
    @State private var showMenu: Bool = false
    @State private var showSettings: Bool = false

    @Environment(\.resetFocus) var resetFocus
    @Namespace private var namespace

    var body: some View {
        ZStack {

            if showSettings {
                SettingsScreen(closeAction: {
                    withAnimation {
                        showSettings = false
                    }
                })
            } else {
                if showMenu {
                    StandardLayout()
                } else {
                    StandardLayout()
                        .focusable()
                }
            }

            if showMenu {
                MainMenu(action: { mainMenuItem in
                    print("selected menu item: \(mainMenuItem)")

                    switch mainMenuItem {
                    case .home:
                        showMenu = false

                    case .settings:
                        withAnimation(.easeOut) {
                            showMenu = false
                            showSettings = true
                        }

                    case .logout:
                        Task {
                            buildings.logout()
                        }
                    }
                })
            }
        }
        .focusScope(namespace)
        .onAppear {
            resetFocus(in: namespace)
            startRefreshing()
        }
        .onDisappear {
            stopRefreshing()
        }
        .onTapGesture {
            if !showMenu && !showSettings {
                print("remote tap - refresh all")
                refreshAll()
            }
        }
        .onExitCommand {
            if showSettings {
                print("exit command - close settings")
                showSettings = false
                return
            }

            if !showMenu {
                print("exit command - show menu")
                showMenu = true
                return
            }

            print("exit command - dismiss")
            exit(0)
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
