import SwiftUI

// MARK: - Hex Color Extension

extension Color {
    init(hex6: UInt32) {
        self.init(
            red: Double((hex6 >> 16) & 0xFF) / 255,
            green: Double((hex6 >> 8) & 0xFF) / 255,
            blue: Double(hex6 & 0xFF) / 255
        )
    }
}

// MARK: - Card Style Modifier

struct CardStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThickMaterial)
            }
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyleModifier())
    }
}

// MARK: - Card Button Style

/// Press feedback for a whole card acting as one button.
///
/// A card that opens something looks exactly like one that does not, and a
/// chevron small enough not to shout is also small enough to miss. Reacting
/// the instant a finger lands says "this is a control" without drawing
/// anything extra while at rest — and using a real `Button` gets the
/// accessibility button trait along with it.
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.75 : 1)
            .animation(
                .spring(response: 0.25, dampingFraction: 0.7),
                value: configuration.isPressed
            )
    }
}

#Preview("Card Style") {
    VStack(spacing: 20) {
        Text("Hello World")
            .cardStyle()

        HStack(spacing: 10) {
            Text("Left")
                .cardStyle()
            Text("Right")
                .cardStyle()
        }
    }
    .padding()
}
