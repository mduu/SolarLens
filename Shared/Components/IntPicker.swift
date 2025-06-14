//

import SwiftUI

struct IntPicker: View {
    @Binding var value: Int
    var step: Int = 5
    var min: Int = 0
    var max: Int = 100
    var tintColor: Color = .accent
    var unit: LocalizedStringResource = "%"

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

            HStack(spacing: 2) {
                Text(verbatim: "\(value)")
                Text(unit)
            }

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
        IntPicker(
            value: .constant(42)
        )

        Spacer()
    }
}
