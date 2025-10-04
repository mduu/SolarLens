import SwiftUI

struct ContentView: View {
    @Environment(CurrentBuildingState.self) var buildings: CurrentBuildingState

    @State private var selectedTab: TabIdentifier = .home
    enum TabIdentifier {
        case home
        case settings
        case logout
    }

    var body: some View {
        if buildings.loginCredentialsExists {
            TabView(selection: $selectedTab) {

                Tab("Home", systemImage: "house", value: .home) {
                    HomeScreen()
                        .tabBarMinimizeBehavior(.automatic)
                }

                Tab("Settings", systemImage: "gear", value: .settings) {
                    NavigationStack {
                        SettingsScreen()
                            .navigationTitle("Settings")
                    }
                }

                Tab("Log out", systemImage: "arrowshape.turn.up.left", value: .logout) {
                    NavigationStack {
                        LogoutScreen()
                            .navigationTitle("Log out")
                    }
                }
            }
            .tabViewStyle(.sidebarAdaptable)

        } else {
            LoginScreen()
        }
    }
}

#Preview("Standard") {
    ContentView()
        .environment(CurrentBuildingState.fake())
        .environment(UiContext())
}

#Preview("Login") {
    ContentView()
        .environment(CurrentBuildingState())
        .environment(UiContext())
}
