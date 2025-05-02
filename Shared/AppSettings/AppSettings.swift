import SwiftUI

class AppSettings {

    @AppStorage(AppStorageKeys.appearanceUseGlowEffect)
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
    
    @AppStorage(AppStorageKeys.onboardingShown)
    var onboardingShown: Bool?

    var onboardingShownWithDefault: Binding<Bool> {
        Binding<Bool>(
            get: {
                self.onboardingShown ?? false
            },
            set: { newValue in
                print(
                    "Change onboardingShown to \(newValue) from \(String(describing: self.onboardingShown))"
                )
                self.onboardingShown = newValue
            }
        )
    }
    
    var needToShowOnboarding: Binding<Bool> {
        Binding<Bool>(
            get: {
                !(self.onboardingShown ?? false)
            },
            set: { newValue in
                print(
                    "Change onboardingShown to \(newValue) from \(String(describing: self.onboardingShown))"
                )
                self.onboardingShown = !newValue
            }
        )
    }
}
