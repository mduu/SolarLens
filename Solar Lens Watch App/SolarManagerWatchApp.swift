import SwiftUI

@main
struct SolarManagerWatch_Watch_AppApp: App {
    @WKApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State var currentBuildingState = CurrentBuildingState(energyManagerClient: SolarManager.shared)
    @State var navigationState = NavigationState()
    @State var automationStateStore = AutomationStateStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    AppStoreReviewManager.shared.increaseStartupCount()
                }
                .environment(currentBuildingState)
                .environment(navigationState)
                .environment(automationStateStore)
        }
        // For testing specific locale, uncomment:
        // .environment(\.locale, Locale(identifier: "de"))
    }
}

class AppDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        // Activate WatchConnectivity early so the delegate is set before
        // iOS delivers any queued transferUserInfo / applicationContext
        // from a freshly-paired or recently-launched companion. The
        // session class is a plain NSObject — no observable state — so
        // its existence and delegate callbacks don't interact with the
        // SwiftUI Observation framework at all.
        AutomationWatchSession.shared.start()
    }
}
