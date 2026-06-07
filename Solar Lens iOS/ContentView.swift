import SwiftUI

enum AppTab: Hashable {
    case now
    case automation
    case notifications
    case statistics
}

struct ContentView: View {
    @Environment(CurrentBuildingState.self) var buildingState: CurrentBuildingState
    @State private var automationManager = AutomationManager.shared
    @State private var notificationManager = NotificationManager.shared
    @State private var tabSelection = TabSelection.shared

    var body: some View {
        @Bindable var tabSelection = tabSelection

        if !buildingState.loginCredentialsExists {
            LoginScreen()
        } else {
            TabView(selection: $tabSelection.selectedTab) {
                Tab("Now", systemImage: "bolt.fill", value: AppTab.now) {
                    HomeScreen()
                        .topLevelTabSwipe()
                }

                if buildingState.overviewData.hasAnyBattery
                    || buildingState.overviewData.hasAnyCarChargingStation
                {
                    Tab(
                        "Automation",
                        systemImage: "wand.and.stars",
                        value: AppTab.automation
                    ) {
                        AutomationScreen()
                            .topLevelTabSwipe()
                    }
                    .badge(
                        automationManager.activeAutomation != nil
                            ? Text(Image(systemName: "bolt.car.circle.fill"))
                            : nil
                    )
                }

                Tab(
                    "Notifications",
                    systemImage: "bell.badge.fill",
                    value: AppTab.notifications
                ) {
                    NotificationsScreen()
                        .topLevelTabSwipe()
                }
                .badge(
                    notificationManager.hasActiveMonitors
                        ? Text("\(notificationManager.activeMonitors.count)")
                        : nil
                )

                Tab(
                    "Statistics",
                    systemImage: "chart.bar.fill",
                    value: AppTab.statistics
                ) {
                    // StatisticsScreen has its own period-paging swipe;
                    // it bubbles up to switch the top-level tab when the
                    // user crosses the today (first-period) boundary.
                    StatisticsScreen()
                }
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        // solarlens://automation → switch to the Automation tab.
        // The host of the URL is the section identifier; path / query
        // reserved for future per-section deep links.
        guard url.scheme == "solarlens" else { return }
        switch url.host {
        case "automation":
            tabSelection.selectedTab = .automation
        case "notifications":
            tabSelection.selectedTab = .notifications
        case "home", "now":
            tabSelection.selectedTab = .now
        case "statistics":
            tabSelection.selectedTab = .statistics
        default:
            break
        }
    }
}

#Preview {
    ContentView()
}
