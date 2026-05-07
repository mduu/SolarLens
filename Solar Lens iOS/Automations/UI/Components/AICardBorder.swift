import SwiftUI

/// Animated gradient border for the *running* state of an automation card.
/// The angular gradient rotates slowly, giving an "AI thinking" feel that
/// is clearly distinct from the static gradient fill of an idle card.
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
                        colors: [
                            Color(red: 0.42, green: 0.13, blue: 0.78),
                            Color(red: 0.85, green: 0.20, blue: 0.55),
                            Color(red: 0.18, green: 0.32, blue: 0.86),
                            Color(red: 0.42, green: 0.13, blue: 0.78),
                        ],
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
