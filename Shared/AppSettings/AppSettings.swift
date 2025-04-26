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
}
