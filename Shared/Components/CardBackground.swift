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

// MARK: - Card Metrics

/// The one description of a card's geometry. The radius used to be retyped as
/// a literal wherever a card-shaped thing was drawn, which is how the sheets
/// ended up on 16 while the home screen sits on 20.
enum CardMetrics {
    static let cornerRadius: CGFloat = 20
    static let horizontalPadding: CGFloat = 14
    static let verticalPadding: CGFloat = 16

    static var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius)
    }
}

// MARK: - Card Style Modifier

struct CardStyleModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityShowButtonShapes) private var showButtonShapes
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, CardMetrics.horizontalPadding)
            .padding(.vertical, CardMetrics.verticalPadding)
            .frame(maxWidth: .infinity)
            .background {
                CardMetrics.shape
                    .fill(.ultraThickMaterial)
            }
            .overlay {
                CardMetrics.shape
                    .strokeBorder(
                        Color.primary.opacity(strokeOpacity),
                        lineWidth: strokeWidth
                    )
            }
    }

    /// Measured against a real screenshot, a card's interior sat five levels of
    /// 255 away from the sky behind it — the panels barely existed as shapes.
    /// This gives them an edge.
    ///
    /// `Color.primary` rather than a fixed colour, and `strokeBorder` rather
    /// than `stroke`, so the line is drawn *inside* the card, over its own
    /// material. That makes it self-normalising: when the animated background
    /// brightens the translucent card, the line brightens with it and the
    /// contrast between them holds.
    private var strokeOpacity: Double {
        if showButtonShapes {
            // The user has told the system they cannot pick out borderless
            // controls. Answer that rather than guessing at a compromise.
            return colorScheme == .dark ? 0.34 : 0.26
        }
        if reduceTransparency {
            return colorScheme == .dark ? 0.20 : 0.16
        }
        return colorScheme == .dark ? 0.14 : 0.10
    }

    /// A sub-point hairline is halved again by antialiasing, which makes its
    /// effective alpha differ between @2x and @3x. One point at a lower alpha
    /// is the controllable knob.
    private var strokeWidth: CGFloat {
        showButtonShapes ? 1.5 : 1
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

// MARK: - Disclosure Chevron

/// The "this leads somewhere" marker every tappable card wears.
///
/// One definition, because three hand-rolled copies had already drifted apart
/// — the energy cards were a step darker than the charging and device rows.
struct DisclosureChevron: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
    }
}

extension View {
    /// Marks a card as leading somewhere.
    ///
    /// Deliberately an overlay rather than a column in the layout: it sits in
    /// the padding ring the card already spends, so the content keeps the full
    /// width. A column cost these half-screen cards enough room that the
    /// efficiency gauges had to shrink to fit beside one.
    func cardDisclosure() -> some View {
        overlay(alignment: .trailing) {
            DisclosureChevron()
                .padding(.trailing, 5)
        }
    }
}

private struct CardSample: View {
    var body: some View {
        HStack(spacing: 10) {
            Text("Left").cardStyle()

            HStack(spacing: 3) {
                Text("Right")
                DisclosureChevron()
            }
            .cardStyle()
        }
        .padding()
    }
}

#Preview("Card Style") {
    CardSample()
}

// The accessibility environment values are read-only, so Button Shapes and
// Reduce Transparency cannot be previewed — check those on a booted simulator
// (`simctl spawn booted defaults write com.apple.Accessibility …`) or on device.

#Preview("Dark") {
    CardSample()
        .preferredColorScheme(.dark)
}
