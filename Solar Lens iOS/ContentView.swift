import SwiftUI

enum AppTab: Hashable {
    case now
    case automation
    case statistics
}

struct ContentView: View {
    @Environment(CurrentBuildingState.self) var buildingState: CurrentBuildingState
    @State private var automationManager = AutomationManager.shared
    @State private var selectedTab: AppTab = .now

    var body: some View {
        if !buildingState.loginCredentialsExists {
            LoginScreen()
        } else {
            TabView(selection: $selectedTab) {
                Tab("Now", systemImage: "bolt.fill", value: AppTab.now) {
                    HomeScreen()
                }

                Tab(
                    "Automation",
                    systemImage: "wand.and.stars",
                    value: AppTab.automation
                ) {
                    AutomationScreen()
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
            selectedTab = .automation
        case "home", "now":
            selectedTab = .now
        case "statistics":
            selectedTab = .statistics
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
