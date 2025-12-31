import SwiftUI

struct Column1View: View {
    private let storageManager = ImageStorageManager.shared

    @State var hasCustomLogo: Bool = false

    var body: some View {
        VStack {

            if hasCustomLogo {
                CustomLogoView()
                    .frame(maxWidth: .infinity, maxHeight: 70)
                    .padding(.bottom, 20)
            }

            CurrentEnergyFlowWidget()
                .frame(maxWidth: .infinity)
                .padding(.bottom, 20)

            SolarForecastWidget()
                .frame(maxHeight: .infinity)

        }
        .onAppear {
            hasCustomLogo = storageManager.loadCustomLogo() != nil
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
