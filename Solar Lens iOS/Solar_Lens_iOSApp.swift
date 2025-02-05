import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct Solar_Lens_iOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @State var currentBuildingState = CurrentBuildingState(
        energyManagerClient: SolarManager.instance())

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(currentBuildingState)
        }
        //.environment(\.locale, Locale(identifier: "DE"))
    }
}
