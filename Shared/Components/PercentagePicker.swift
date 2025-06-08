//

import SwiftUI

struct PercentagePicker: View {
    @Binding var value: Int
    var step: Int = 5
    var min: Int = 0
    var max: Int = 100
    var tintColor: Color = .accent

    var body: some View {
        HStack {
            Button(action: {
                withAnimation {
                    value = Swift.max(min, value - step)
                }
            }) {
                Image(systemName: "minus")
                    .frame(height: 20)
            }
            .buttonBorderShape(.circle)
            .buttonStyle(.bordered)
            .tint(tintColor)

            Text(verbatim: "\(value)%")
                .animation(.bouncy)

            Button(action: {
                withAnimation {
                    value = Swift.min(max, value + step)
                }
            }) {
                Image(systemName: "plus")
                    .frame(height: 20)
            }
            .buttonBorderShape(.circle)
            .buttonStyle(.bordered)
            .tint(tintColor)
            
        } // :HStack
    }
}

#Preview {
    VStack {
        PercentagePicker(
            value: .constant(42)
        )

        Spacer()
    }
}
