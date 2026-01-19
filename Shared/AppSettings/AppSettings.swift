import SwiftUI

struct AppSettings {

    @AppStorage("appearanceUseGlowEffect")
    var appearanceUseGlowEffect: Bool?
    var appearanceUseGlowEffectWithDefault: Binding<Bool> {
        Binding<Bool>(
            get: {
                self.appearanceUseGlowEffect ?? false
            },
            set: { newValue in
                print(
                    "Change appearanceUseGlowEffect to \(newValue) from \(String(describing: self.appearanceUseGlowEffect))"
                )
                self.appearanceUseGlowEffect = newValue
            }
        )
    }

    @AppStorage("onboardingShown.9")
    var showOnboarding: Bool = true
    
    @AppStorage("surveyForeverDismissed")
    var surveyForeverDismissed: Bool = false
    
    @AppStorage("surveyLastShownDate")
    var surveyLastShownDate: Double = 0.0
}
