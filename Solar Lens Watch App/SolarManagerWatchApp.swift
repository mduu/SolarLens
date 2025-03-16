import SwiftUI

@main
struct SolarManagerWatch_Watch_AppApp: App {
    @WKApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @State var currentBuildingState = CurrentBuildingState(energyManagerClient: SolarManager.instance())
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
        //.environment(\.locale, Locale(identifier: "DE"))
    }
}

class AppDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        // TODO Code here
    }
}
