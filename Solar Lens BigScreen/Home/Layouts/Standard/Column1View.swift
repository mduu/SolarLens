import SwiftUI

struct Column1View: View {
    var body: some View {
        VStack {
            CurrentEnergyFlowWidget()
                .frame(maxWidth: .infinity)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HStack {
        Column1View()
            .environment(CurrentBuildingState.fake())
            .frame(maxWidth: 400)

        Spacer()
    }
    .background(.blue.gradient)
}
