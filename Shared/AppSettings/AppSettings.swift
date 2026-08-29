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

    /// Story #9: lets the Solar Lens server send a push at a scheduled
    /// automation's end time so it runs on time even after a force quit.
    /// Only the device token and the timestamp are sent — see ADR-006.
    @AppStorage("serverAssistedTiming")
    var serverAssistedTiming: Bool?
    var serverAssistedTimingWithDefault: Binding<Bool> {
        Binding<Bool>(
            get: { self.serverAssistedTiming ?? true },
            set: { newValue in self.serverAssistedTiming = newValue }
        )
    }

    @AppStorage("onboardingShown.9")
    var showOnboarding: Bool = true
}
