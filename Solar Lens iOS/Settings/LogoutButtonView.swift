import SwiftUI

struct LogoutButtonView: View {
    @Environment(CurrentBuildingState.self) var buildingState:
        CurrentBuildingState
    @State var showLogoutConfirmation: Bool = false

    var body: some View {
        Button {
            showLogoutConfirmation = true
        } label: {
            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                .font(.caption)
                .foregroundStyle(.red)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.red.opacity(0.12), in: Capsule())
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
