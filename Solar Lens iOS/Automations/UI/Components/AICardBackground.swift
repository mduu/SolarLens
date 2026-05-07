import SwiftUI

/// Purple/pink/blue gradient with a subtle slow shimmer when `isAnimating`.
/// Used as the background for automation cards to give them an "AI" feel.
struct AICardBackground: View {
    var isAnimating: Bool = false
    var cornerRadius: CGFloat = 20
    var opacity: Double = 0.85

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.1, paused: !isAnimating)) {
            context in
            let phase = isAnimating
                ? CGFloat(context.date.timeIntervalSinceReferenceDate)
                    .truncatingRemainder(dividingBy: 6) / 6
                : 0

            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.42, green: 0.13, blue: 0.78),
                            Color(red: 0.85, green: 0.20, blue: 0.55),
                            Color(red: 0.18, green: 0.32, blue: 0.86),
                        ],
                        startPoint: UnitPoint(
                            x: 0.0 + phase, y: 0.0
                        ),
                        endPoint: UnitPoint(
                            x: 1.0 + phase, y: 1.0
                        )
                    )
                )
                .opacity(opacity)
        }
    }
}

#Preview {
    VStack {
        AICardBackground(isAnimating: false)
            .frame(height: 120)
        AICardBackground(isAnimating: true)
            .frame(height: 120)
    }
    .padding()
}
