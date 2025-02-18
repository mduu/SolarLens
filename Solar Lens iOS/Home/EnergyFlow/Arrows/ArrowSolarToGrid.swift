import SwiftUI

struct ArrowSolarToGrid: View {
    var isActive: Bool
    
    var body: some View {
        if isActive {
            Image(systemName: "arrow.right")
                .foregroundColor(.orange)
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
    ArrowSolarToGrid(isActive: true)
        .frame(width: 50, height: 50)
}
