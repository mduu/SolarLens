import SwiftUI

struct Column1: View {
    var body: some View {
        VStack {
            CurrentEnergyFlow()
                .padding()
                .frame(maxWidth: .infinity)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    Column1()
}
