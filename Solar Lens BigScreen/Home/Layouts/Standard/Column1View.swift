import SwiftUI

struct Column1View: View {
    var body: some View {
        VStack {
            CurrentEnergyFlowWidget()
                .frame(maxWidth: .infinity)
                .padding(.bottom, 30)

            SolarForecastWidget()
                .frame(maxHeight: .infinity)

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
