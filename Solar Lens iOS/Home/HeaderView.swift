import SwiftUI

struct HeaderView: View {
    @Environment(CurrentBuildingState.self) var buildingState:
        CurrentBuildingState
    @Environment(\.colorScheme) var colorScheme
    @State var showLogoutConfirmation: Bool = false

    var body: some View {
        HStack {
            HStack {
                Text("")
                Spacer()
            }

            AppLogo()

            HStack {
                Spacer()

                LogoutButtonView()
                    .padding(.trailing, 30)
            }

        }  // :HStack
    }
}

#Preview("top center") {
    VStack {
        HeaderView()
            .environment(
                CurrentBuildingState.fake(
                    overviewData: OverviewData.fake()))

        Spacer()
    }
}

#Preview("small") {
    VStack {
        HeaderView()
            .environment(
                CurrentBuildingState.fake(
                    overviewData: OverviewData.fake())
            )
            .frame(width: 350, height: 100)
    }
}
