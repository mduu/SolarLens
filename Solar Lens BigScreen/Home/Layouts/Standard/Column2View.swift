import SwiftUI

struct Column2View: View {
    var body: some View {
        VStack {
            TodayWidget()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HStack {

        Column2View()
            .environment(CurrentBuildingState.fake())
            .frame(maxWidth: 400)

        Spacer()
    }
    .background(.blue.gradient)
}
