import SwiftUI

/// How much horizontal room a screen has to lay itself out in.
///
/// Decided by the width a view is actually given, not by the device: an iPad
/// in a narrow Split View column, a Stage Manager window and a Mac window all
/// land in the step that fits them. The iPhone always stays `compact`, so its
/// portrait and landscape layouts are untouched.
enum LayoutWidth: Comparable {
    /// iPhone, and an iPad window too narrow for more than the phone layout.
    case compact
    /// iPad mini, an 11" iPad in portrait, half of a 13" screen: two columns.
    case medium
    /// 11"/13" landscape, 13" portrait, Mac windows: three columns and room
    /// for a detail pane beside the content.
    case wide

    static let mediumMinimum: CGFloat = 700
    static let wideMinimum: CGFloat = 1000

    static func from(width: CGFloat) -> LayoutWidth {
        if UIDevice.current.userInterfaceIdiom == .phone { return .compact }
        if width < mediumMinimum { return .compact }
        if width < wideMinimum { return .medium }
        return .wide
    }
}

extension EnvironmentValues {
    /// The width step of the nearest `LayoutWidthReader`.
    @Entry var layoutWidth: LayoutWidth = .compact
}

/// Measures the width its content is given and hands the matching
/// `LayoutWidth` down, both as a closure argument and in the environment.
struct LayoutWidthReader<Content: View>: View {
    @ViewBuilder var content: (LayoutWidth) -> Content

    var body: some View {
        GeometryReader { geometry in
            let layout = LayoutWidth.from(width: geometry.size.width)
            content(layout)
                .environment(\.layoutWidth, layout)
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

extension View {
    /// Continues a background under the iPad's sidebar, so the sidebar's
    /// glass picks up the screen's colours instead of a flat grey.
    @ViewBuilder
    func extendedUnderSidebar(_ isEnabled: Bool = true) -> some View {
        if #available(iOS 26.0, *), isEnabled {
            backgroundExtensionEffect()
        } else {
            self
        }
    }

    /// Keeps lists and forms from running edge to edge on a large screen.
    func readableContentWidth(_ maxWidth: CGFloat = 720) -> some View {
        frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }
}
