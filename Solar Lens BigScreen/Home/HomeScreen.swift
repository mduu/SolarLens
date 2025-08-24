import SwiftUI

struct HomeScreen: View {
    var body: some View {
        StandardLayout()
    }
}

#Preview {
    HomeScreen()
        .environment(CurrentBuildingState.fake())
        .environment(UiContext())
}
