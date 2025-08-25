import SwiftUI

struct HomeScreen: View {
    @Environment(CurrentBuildingState.self) var buildings: CurrentBuildingState

    var body: some View {
        StandardLayout()
            .onAppear {
                Task {
                    await buildings.fetchServerData()
                }
            }
    }
}

#Preview {
    HomeScreen()
        .environment(CurrentBuildingState.fake())
        .environment(UiContext())
}
