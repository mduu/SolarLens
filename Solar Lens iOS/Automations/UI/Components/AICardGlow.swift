import SwiftUI

/// Soft outer glow for the *running* state of an automation card.
/// Renders the same rotating angular gradient as `AICardBorder` but
/// blurred into a halo and placed behind the card.
struct AICardGlow: View {
    var cornerRadius: CGFloat = 20
    var blurRadius: CGFloat = 12
    var opacity: Double = 0.45

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let angle = Angle.degrees(
                t.truncatingRemainder(dividingBy: 6) * 60
            )
            // Subtle 4-second breath on top of the rotation.
            let breath = 0.85
                + 0.15 * sin(t.truncatingRemainder(dividingBy: 4) / 4 * 2 * .pi)

            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    AngularGradient(
                        colors: [
                            Color(red: 0.42, green: 0.13, blue: 0.78),
                            Color(red: 0.85, green: 0.20, blue: 0.55),
                            Color(red: 0.18, green: 0.32, blue: 0.86),
                            Color(red: 0.42, green: 0.13, blue: 0.78),
                        ],
                        center: .center,
                        angle: angle
                    )
                )
                .blur(radius: blurRadius)
                .opacity(opacity * breath)
        }
    }
}

#Preview {
    ZStack {
        Color(.systemBackground)
        VStack {
            Text("Battery → Car running")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.regularMaterial)
                )
                .overlay(AICardBorder())
                .background(AICardGlow().padding(-14))
                .padding(28)
        }
    }
}
