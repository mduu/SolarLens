import SwiftUI

struct AppSettings {

    @AppStorage("appearanceUseWarmBackground")
    var appearanceUseWarmBackground: Bool?
    var appearanceUseWarmBackgroundWithDefault: Binding<Bool> {
        Binding<Bool>(
            get: {
                self.appearanceUseWarmBackground ?? true
            },
            set: { newValue in
                self.appearanceUseWarmBackground = newValue
            }
        )
    }

    @AppStorage("onboardingShown.9")
    var showOnboarding: Bool = true
}
