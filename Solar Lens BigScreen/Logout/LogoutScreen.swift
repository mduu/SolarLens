import SwiftUI

struct LogoutScreen: View {
    @Environment(CurrentBuildingState.self) var buildings: CurrentBuildingState

    var body: some View {
        HStack {

            Button (action: {
            }) {
                Text("Don't log out")
                    .font(.title)
                    .foregroundColor(.primary)
                    .padding(30)
                    
            }
            .buttonStyle(.bordered)


            Button(action: {
                Task {
                    buildings.logout()
                }
            }) {
                Label("Log out", systemImage: "door.left.hand.open")
                    .font(.title)
                    .padding(30)
                    .foregroundColor(.red)
            }
            .buttonStyle(.bordered)

        }
    }
}

#Preview {
    LogoutScreen()
        .environment(CurrentBuildingState.fake())
}
