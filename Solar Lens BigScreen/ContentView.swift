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

#Preview {
    ContentView()
        .environment(CurrentBuildingState())
}
