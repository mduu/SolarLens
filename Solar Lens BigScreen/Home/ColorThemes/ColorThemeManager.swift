internal import Foundation
import SwiftUI

class ColorThemeManager {
    @AppStorage(
        "currentColorThemeId"
    ) var selectedThemeId: String = StandardTheme.id

    func themeById(id: String) -> ColorTheme {
        switch id {
        case StandardTheme.id:
        default:
            return StandardTheme()
        }
    }
}
