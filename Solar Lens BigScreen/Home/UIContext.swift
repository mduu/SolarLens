import Observation

@Observable
class UiContext {

    var currentColorTheme: ColorTheme;

    private let colorThemeManager: ColorThemeManager = ColorThemeManager()

    init() {
        currentColorTheme = self.colorThemeManager.currentTheme
    }
}
