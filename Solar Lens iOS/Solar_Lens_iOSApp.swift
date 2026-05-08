import SwiftUI
internal import UserNotifications

@main
struct Solar_Lens_iOSApp: App {
    @State var currentBuildingState = CurrentBuildingState(
        energyManagerClient: SolarManager.shared)
    @Environment(\.scenePhase) private var scenePhase

    init() {
        AutomationManager.shared.registerBackgroundTask()

        // Make automation notifications visible while the app is in the
        // foreground — without this iOS only adds them to Notification
        // Center and the user has to leave the app to see them.
        UNUserNotificationCenter.current().delegate =
            AutomationNotificationDelegate.shared
        AutomationNotificationDelegate.shared.registerCategories()

        LiveActivityCancelHandler.shared = {
            AutomationManager.shared.cancelActiveAutomation()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(currentBuildingState)
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    AutomationManager.shared
                        .handleScenePhaseChange(oldPhase, newPhase)
                }
        }
        //.environment(\.locale, Locale(identifier: "DE"))
    }
}
