import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = BuildingStateViewModel()

    var body: some View {
        if !viewModel.loginCredentialsExists {
            LoginView()
                .environmentObject(viewModel)
        } else {
            HomeView()
                .environmentObject(viewModel)
        }
    }
}

#Preview {
    ContentView()
}
