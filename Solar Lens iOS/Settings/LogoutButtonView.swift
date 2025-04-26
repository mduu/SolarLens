import SwiftUI

struct LogoutButtonView: View {
    @Environment(CurrentBuildingState.self) var buildingState:
        CurrentBuildingState
    @State var showLogoutConfirmation: Bool = false

    var body: some View {
        RoundIconButton(
            imageName: "iphone.and.arrow.right.outward",
            imageColor: Color.red,
            action: {
                showLogoutConfirmation = true
            }
        )
        .confirmationDialog(
            "Are you sure to log out?",
            isPresented: $showLogoutConfirmation
        ) {
            Button("Confirm") {
                buildingState.logout()
            }.foregroundColor(.red)
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
