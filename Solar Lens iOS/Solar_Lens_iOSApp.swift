import SwiftUI

@main
struct Solar_Lens_iOSApp: App {
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
