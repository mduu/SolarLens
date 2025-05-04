import SwiftUI

struct ArrowSolarToBattery: View {
    var isActive: Bool

    var body: some View {
        if isActive {
            Image(systemName: "arrow.down")
                .foregroundColor(.green)
                .font(
                    .system(
                        size: 15, weight: .light)
                )
                .symbolEffect(
                    .wiggle.byLayer,
                    options: .repeat(
                        .periodic(delay: 0.7)))

        } else {
            Text("")
                .frame(minWidth: 15, minHeight: 15)
        }
    }
}

#Preview {
    ArrowSolarToBattery(isActive: true)
        .frame(width: 15, height: 15)
}
