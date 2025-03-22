import SwiftUI

struct ArrowBatteryToHouse: View {
    var isActive: Bool

    var body: some View {
        if isActive {
            Image(systemName: "arrow.right")
                .foregroundColor(.green)
                .font(
                    .system(
                        size: 15, weight: .light)
                )
                .symbolEffect(
                    .wiggle.byLayer,
                    options: .repeat(
                        .periodic(delay: 0.7))
                )
        } else {
            Text("")
                .frame(minWidth: 15, minHeight: 15)
        }

    }
}

#Preview {
    ArrowBatteryToHouse(isActive: true)
        .frame(width: 50, height: 50)
        .background(.green.opacity(0.2))
}
