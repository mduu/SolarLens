import SwiftUI

@main
struct SolarManagerWatch_Watch_AppApp: App {
    @WKApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State var currentBuildingState = CurrentBuildingState(energyManagerClient: SolarManager.shared)
    @State var navigationState = NavigationState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    AppStoreReviewManager.shared.increaseStartupCount()
                }
                .environment(currentBuildingState)
                .environment(navigationState)
        }
        // For testing specific locale, uncomment:
        // .environment(\.locale, Locale(identifier: "de"))
    }
}

class AppDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        // No watch-side automation surface in 4.1 — the WatchConnectivity
        // bridge that 4.1.0 (builds 316–325) shipped consistently triggered
        // a multi-hour freeze on real Apple Watch hardware that we could
        // not pin down to a single cause within reasonable iteration cost.
        // The iOS-side automation feature remains intact, and running
        // automations are still visible on the watch via the system Live
        // Activity (mirrored automatically to the Lock Screen / Smart
        // Stack). To be revisited in a future version.
    }
}
