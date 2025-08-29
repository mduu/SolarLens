import SwiftUI

struct ArrowBatteryToHouse: View {
    var isActive: Bool
    
    var body: some View {
        if isActive {
            Image(systemName: "arrow.right")
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
                .frame(minWidth: 50, minHeight: 50)
        }
    }
}

#Preview {
    ArrowBatteryToHouse(isActive: true)
        .frame(width: 50, height: 50)
}
