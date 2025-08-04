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
            handleScenePhaseChange(oldPhase, newPhase)
        }
        //.environment(\.locale, Locale(identifier: "DE"))
    }

    init() {
        ScenarioManager.shared.registerBackgroundTask()
    }

    private func handleScenePhaseChange(
        _ oldPhase: ScenePhase,
        _ newPhase: ScenePhase
    ) {
        ScenarioManager.shared.handleScenePhaseChange(oldPhase, newPhase)
    }
}
