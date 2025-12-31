import SwiftUI

struct StandardLayout: View {
    @Environment(UiContext.self) var uiContext: UiContext
    @Environment(CurrentBuildingState.self) var buildings: CurrentBuildingState

    var body: some View {

        VStack {
            HStack {
                Column1View()
                    .frame(maxWidth: .infinity)

                Column2View()
                    .frame(maxWidth: .infinity)

                Column3View()
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)

            FooterView(
                isLoading: buildings.isLoading,
                lastUpdate: buildings.overviewData.lastSuccessServerFetch
            )
            .frame(maxHeight: 50)
            .padding(.all, 0)
        }

    }
}

#Preview {
    StandardLayout()
        .environment(CurrentBuildingState.fake())
        .environment(UiContext())
}
