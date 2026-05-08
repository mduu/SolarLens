import SwiftUI
#if os(iOS)
import UIKit
#endif

/// Single source of truth for the visual identity of every Solar Lens
/// automation — both the in-app running card and the iOS Live Activity Lock
/// Screen card. Per-automation card bodies must read from this namespace
/// instead of redefining their own gradient or tint.
///
/// Palette is the Solar Lens brand: yellow (primary, our `AccentColor` and
/// the "solar" semantic) → soft highlight → orange (warning/grid-import
/// semantic). The colours are colour-scheme-aware: in dark mode the yellow,
/// highlight and orange stops are toned down so the rotating border / glow
/// don't read as harsh against a dark Lock Screen or app background.
public enum AutomationBrand {

    public static let gradientColors: [Color] = [
        yellow,
        highlight,
        orange,
    ]

    /// Closed loop for `AngularGradient` (last colour repeats the first so
    /// the rotating border has no visible seam).
    public static let angularGradientColors: [Color] = [
        yellow,
        highlight,
        orange,
        yellow,
    ]

    /// Glyph used to mark "this is a Solar Lens automation".
    public static let accentSymbol: String = "sparkles"

    /// Foreground style for the brand mark (sparkles + title gradient).
    public static var titleGradient: LinearGradient {
        LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Stops

    /// Dynamic yellow: vibrant in light mode, muted (≈70 % luminance) in dark
    /// mode where it would otherwise glare against a dark backdrop.
    private static let yellow: Color = {
        #if os(iOS)
        return Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.95, green: 0.78, blue: 0.20, alpha: 1.0)
                : UIColor.systemYellow
        })
        #else
        return .yellow
        #endif
    }()

    /// Dynamic warm highlight that replaces pure white. Pure white is the
    /// main offender in dark mode — it punches through any backdrop. In
    /// light mode this stays as a near-white highlight; in dark mode it
    /// dims to a soft, low-saturation gold.
    private static let highlight: Color = {
        #if os(iOS)
        return Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.85, green: 0.78, blue: 0.55, alpha: 1.0)
                : UIColor(red: 1.00, green: 0.96, blue: 0.85, alpha: 1.0)
        })
        #else
        return Color(white: 0.95)
        #endif
    }()

    /// Dynamic orange: vibrant in light mode, muted in dark mode.
    private static let orange: Color = {
        #if os(iOS)
        return Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.90, green: 0.50, blue: 0.18, alpha: 1.0)
                : UIColor.systemOrange
        })
        #else
        return .orange
        #endif
    }()
}
