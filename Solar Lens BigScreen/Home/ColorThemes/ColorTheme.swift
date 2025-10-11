import SwiftUI

protocol ColorTheme {

    /// Technical internal unique identifier
    static var id: String { get }

    /// UI Theme Name (multi-langue)
    static var name: LocalizedStringResource { get }

    /// UI Theme description (multi-language)
    static var description: String { get }

    /// Primary foreground color
    static var primaryColor: Color { get }

    // Background color
    static var backgroundTintColor: Color { get }
}
