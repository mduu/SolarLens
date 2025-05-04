import SwiftUI

struct HeaderView: View {
    let onRefresh: () -> Void

    @Environment(CurrentBuildingState.self) var buildingState:
        CurrentBuildingState
    @State var showLogoutConfirmation: Bool = false

    var body: some View {
        HStack {
            HStack {
                RefreshButton(onRefresh: { onRefresh() })
                    .padding(.leading, 30)
                Spacer()
            }

            AppLogo()

            HStack {
                Spacer()

                SettingsButton()
                    .padding(.trailing, 30)
            }

        }  // :HStack
    }
}

#Preview("top center") {
    VStack {
        HeaderView(onRefresh: {})
            .environment(
                CurrentBuildingState.fake(
                    overviewData: OverviewData.fake()
                )
            )

        Spacer()
    }
}

#Preview("small") {
    VStack {
        HeaderView(onRefresh: {})
            .environment(
                CurrentBuildingState.fake(
                    overviewData: OverviewData.fake()
                )
            )
            .frame(width: 350, height: 100)
    }
}
