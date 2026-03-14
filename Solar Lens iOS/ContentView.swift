import SwiftUI

struct ContentView: View {
    @Environment(CurrentBuildingState.self) var buildingState: CurrentBuildingState

    var body: some View {
        if !buildingState.loginCredentialsExists {
            LoginScreen()
        } else {
            TabView {
                Tab("Now", systemImage: "bolt.fill") {
                    HomeScreen()
                }

                Tab("Statistics", systemImage: "chart.bar.fill") {
                    StatisticsScreen()
                }
            }
            .applyLiquidGlassTabBar()
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
