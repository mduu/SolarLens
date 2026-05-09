import SwiftUI

@main
struct SolarManagerWatch_Watch_AppApp: App {
    @WKApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @State var currentBuildingState = CurrentBuildingState(energyManagerClient: SolarManager.shared)
    @State var navigationState = NavigationState()
    @State var automationWatchClient = AutomationWatchClient.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    AppStoreReviewManager.shared.increaseStartupCount()
                }
                .environment(currentBuildingState)
                .environment(navigationState)
                .environment(automationWatchClient)
        }
        // For testing specific locale, uncomment:
        // .environment(\.locale, Locale(identifier: "de"))
    }
}

class AppDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        // Activate WatchConnectivity early so the delegate is set before
        // iOS delivers any queued transferUserInfo / applicationContext
        // from a freshly-paired or recently-launched companion.
        AutomationWatchClient.shared.start()
    }
}
