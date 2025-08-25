import SwiftUI

struct CurrentEnergyFlow: View {
    var body: some View {
        Grid {
            GridRow {
                Text("Current Energy Flow")
                    .font(.headline)
                    .bold()

            }
        }
        .padding(30)
        .frame(height: 300)
        .glassEffect(in: .rect(cornerRadius: 30.0))

    }

}

#Preview {
    VStack {

        HStack {
            CurrentEnergyFlow()
        }
        .frame(maxWidth: .infinity)

    }
    .frame(maxHeight: .infinity)
    .background(.cyan.opacity(0.4))

}
