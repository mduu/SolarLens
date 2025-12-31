import SwiftUI

struct Column3View: View {
    var body: some View {
        VStack {
            CurrentWeekWdiget()
                .padding(.bottom, 20)

            AllTimesStatsWidget()
                .frame(maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ZStack {
        Rectangle()
            .background(.blue.gradient)

        Column3View()
            .frame(maxWidth: 600)
            .environment(CurrentBuildingState.fake())
    }
}
