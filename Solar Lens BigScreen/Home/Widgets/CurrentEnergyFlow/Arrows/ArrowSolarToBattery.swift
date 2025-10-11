import SwiftUI

struct ArrowSolarToBattery: View {
    var isActive: Bool
    
    var body: some View {
        if isActive {
            Image(systemName: "arrow.down")
                .font(
                    .system(
                        size: 50, weight: .light)
                )
                .symbolEffect(
                    .wiggle.byLayer,
                    options: .repeat(
                        .periodic(delay: 0.7)))

        } else {
            Text("")
        }
    }
}

#Preview {
    ArrowSolarToBattery(isActive: true)
        .frame(width: 50, height: 50)
}
