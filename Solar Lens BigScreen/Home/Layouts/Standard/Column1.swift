import SwiftUI

struct Column1: View {
    var body: some View {
        VStack {
            CurrentEnergyFlowWidget()
                .padding()
                .frame(maxWidth: .infinity)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    Column1()
        .environment(CurrentBuildingState.fake())
}
