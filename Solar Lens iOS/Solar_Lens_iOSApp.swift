import SwiftUI

@main
struct Solar_Lens_iOSApp: App {
    @State var currentBuildingState = CurrentBuildingState(
        energyManagerClient: SolarManager.shared)
    @Environment(\.scenePhase) private var scenePhase

    init() {
        AutomationManager.shared.registerBackgroundTask()
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
