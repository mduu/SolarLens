import SwiftUI

@main
struct Solar_Lens_iOSApp: App {
    @Environment(\.scenePhase) private var scenePhase

    @State var currentBuildingState = CurrentBuildingState(
        energyManagerClient: SolarManager.instance()
    )

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(currentBuildingState)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(newPhase)
        }
        //.environment(\.locale, Locale(identifier: "DE"))
    }

    init() {
        // Register background tasks on app launch
        Scenarios.registerScenarioTasks()
    }

    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            print("App became active")
        case .inactive:
            print("App became inactive")
        case .background:
            print("App moved to background - scheduling background tasks")
        @unknown default:
            break
        }
    }
}
