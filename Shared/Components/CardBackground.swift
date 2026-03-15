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
