import SwiftUI

struct ContentView: View {
    @Environment(CurrentBuildingState.self) var buildingState: CurrentBuildingState

    var body: some View {
        if !buildingState.loginCredentialsExists {
            LoginScreen()
        } else {
            HomeScreen()
        }
    }
}

#Preview {
    ContentView()
}
