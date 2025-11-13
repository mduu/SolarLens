import SwiftUI

struct ContentView: View {
    @Environment(CurrentBuildingState.self) var buildingState:
        CurrentBuildingState

    var body: some View {
        if !buildingState.loginCredentialsExists {
            LoginScreen()
        } else {
            TabView {
                Tab("Now", systemImage: "house") {
                    HomeScreen()
                }
                
                Tab("Scenario", systemImage: "deskclock") {
                    ScenarioScreen()
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(
            CurrentBuildingState.fake(
                overviewData: OverviewData.fake(),
                loggedIn: true
            )
        )
}
