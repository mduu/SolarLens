import SwiftUI

/// Animated gradient border for the *running* state of an automation card.
/// The angular gradient rotates slowly, giving an "AI thinking" feel that
/// is clearly distinct from the static gradient fill of an idle card.
///
/// Reads its colour stops from `AutomationBrand` so the in-app running card
/// and the iOS Live Activity Lock Screen card share one visual identity.
struct AICardBorder: View {
    var cornerRadius: CGFloat = 20
    var lineWidth: CGFloat = 5

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let angle = Angle.degrees(
                context.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: 6) * 60
            )

            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    AngularGradient(
                        colors: AutomationBrand.angularGradientColors,
                        center: .center,
                        angle: angle
                    ),
                    lineWidth: lineWidth
                )
        }
    }
}

#Preview {
    ZStack {
        Color(.systemBackground)
        RoundedRectangle(cornerRadius: 20)
            .fill(.regularMaterial)
            .overlay(AICardBorder())
            .frame(height: 160)
            .padding()
    }
}
