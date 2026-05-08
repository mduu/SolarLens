import SwiftUI

/// Solar Lens brand gradient with an optional slow shimmer when `isAnimating`.
/// Used as the background for *idle* automation cards. Active/running cards
/// use `AICardBorder` + `AICardGlow` on top of a material fill instead.
///
/// Reads its colour stops from `AutomationBrand` so the in-app cards and the
/// iOS Live Activity Lock Screen card share one visual identity.
struct AICardBackground: View {
    @Environment(\.colorScheme) private var colorScheme

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
                        colors: AutomationBrand.gradientColors,
                        startPoint: UnitPoint(
                            x: 0.0 + phase, y: 0.0
                        ),
                        endPoint: UnitPoint(
                            x: 1.0 + phase, y: 1.0
                        )
                    )
                )
                .opacity(effectiveOpacity)
        }
    }

    /// Dark mode reads bright warm gradients as glare. Drop the fill to a
    /// quieter level so the card feels like a brand accent rather than a
    /// flashlight.
    private var effectiveOpacity: Double {
        colorScheme == .dark ? opacity * 0.55 : opacity
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
