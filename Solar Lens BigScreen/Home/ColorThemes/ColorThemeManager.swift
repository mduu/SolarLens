internal import Foundation
import SwiftUI

class ColorThemeManager {
    @AppStorage(
        "currentColorThemeId"
    ) var selectedThemeId: String = StandardTheme.id

    var currentTheme: ColorTheme {
        themeById(id: selectedThemeId)
    }

    func themeById(id: String) -> ColorTheme {
        switch id {
        case StandardTheme.id:
            return StandardTheme()

        default:
            return StandardTheme()
        }
    }
}
