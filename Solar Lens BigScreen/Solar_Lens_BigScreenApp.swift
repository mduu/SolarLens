import SwiftUI

@main
struct Solar_Lens_BigScreenApp: App {
    @State var buildingState: CurrentBuildingState = CurrentBuildingState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(buildingState)
        }
    }
}
