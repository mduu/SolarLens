import SwiftUI

struct ContentView: View {
    @Environment(CurrentBuildingState.self) var buildings: CurrentBuildingState

    var body: some View {
        if buildings.loginCredentialsExists {
            HomeScreen()
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
