import SwiftUI

enum AppTab: Hashable {
    case now
    case automation
    case statistics
}

struct ContentView: View {
    @Environment(CurrentBuildingState.self) var buildingState: CurrentBuildingState
    @State private var automationManager = AutomationManager.shared
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
            .applyLiquidGlassTabBar()
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
        case "home", "now":
            tabSelection.selectedTab = .now
        case "statistics":
            tabSelection.selectedTab = .statistics
        default:
            break
        }
    }
}

extension View {
    @ViewBuilder
    func applyLiquidGlassTabBar() -> some View {
        #if os(iOS)
        if #available(iOS 26.0, *) {
            self.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            self
        }
        #else
        self
        #endif
    }
}

#Preview {
    ContentView()
}
