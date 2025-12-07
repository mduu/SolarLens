import SwiftUI

struct WidgetBase<Content: View>: View {
    var title: LocalizedStringResource?
    var content: Content

    @AppStorage("widgetsDarkmode") var widgetsDarkMode: Bool = false

    init(title: LocalizedStringResource?, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var glassMaterial: Glass {
        .clear.tint(
            widgetsDarkMode
                ? .black.opacity(0.28)  // increase to darken more
                : .white.opacity(0.24)  // increase to brighten more
        )
    }

    // Optional overlay to force a deterministic luminance shift regardless of backdrop.
    // Increase/decrease the opacities below to taste, or make them user-controllable.
    @ViewBuilder
    var luminanceOverlay: some View {
        let cornerRadius: CGFloat = 30.0
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                widgetsDarkMode
                    ? Color.black.opacity(0.3)  // darken
                    : Color.white.opacity(0.12)  // brighten
            )
            .allowsHitTesting(false)
    }

    var body: some View {
        VStack {
            WidgetHeaderView(title: title)

            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(.primary)
        .glassEffect(
            glassMaterial,
            in: .rect(cornerRadius: 30.0)
        )
        // Force a predictable darken/brighten on top of glass
        .overlay(luminanceOverlay)
        // Align hit-testing with the visual shape
        .contentShape(.rect(cornerRadius: 30.0))
    }
}

#Preview {
    VStack {
        HStack {

            WidgetBase(title: "Widget Title") {
                Text("Hello Widget")
                    .font(.title)
            }
            .frame(width: 600, height: 500)

            Spacer()
        }

        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.blue.gradient)
}
