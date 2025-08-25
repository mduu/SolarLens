import SwiftUI

struct Column1: View {
    var body: some View {
        VStack {
            CurrentEnergyFlow()
                .frame(maxWidth: .infinity)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    Column1()
}
