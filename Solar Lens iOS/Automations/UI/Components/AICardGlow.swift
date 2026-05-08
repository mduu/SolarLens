import SwiftUI

/// Soft outer glow for the *running* state of an automation card.
/// Renders the same rotating angular gradient as `AICardBorder` but
/// blurred into a halo and placed behind the card.
///
/// Reads its colour stops from `AutomationBrand` so the in-app running card
/// and the iOS Live Activity Lock Screen card share one visual identity.
struct AICardGlow: View {
    @Environment(\.colorScheme) private var colorScheme

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
                        colors: AutomationBrand.angularGradientColors,
                        center: .center,
                        angle: angle
                    )
                )
                .blur(radius: blurRadius)
                .opacity(effectiveOpacity * breath)
        }
    }

    /// Dark mode is much more sensitive to bright halos — a 0.45 opacity
    /// warm glow that reads as a "shimmer" in light mode reads as glare in
    /// dark mode. Halve it.
    private var effectiveOpacity: Double {
        colorScheme == .dark ? opacity * 0.5 : opacity
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
