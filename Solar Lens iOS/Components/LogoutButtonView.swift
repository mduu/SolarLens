import SwiftUI

struct LogoutButtonView: View {
    @Environment(CurrentBuildingState.self) var buildingState:
        CurrentBuildingState
    @State var showLogoutConfirmation: Bool = false

    var body: some View {
        Button(
            "Log out",
            systemImage: "iphone.and.arrow.right.outward"
        ) {
            showLogoutConfirmation = true
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
        .foregroundColor(.primary)
        .font(.system(size: 24))
        .confirmationDialog(
            "Are you sure to log out?",
            isPresented: $showLogoutConfirmation
        ) {
            Button("Confirm") {
                buildingState.logout()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

#Preview {
    LogoutButtonView()
        .environment(
            CurrentBuildingState.fake(
                overviewData: OverviewData.fake()))
        .frame(width: 350, height: 100)
}
