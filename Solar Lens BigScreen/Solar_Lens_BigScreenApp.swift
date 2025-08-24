import SwiftUI

@main
struct Solar_Lens_BigScreenApp: App {
    @State var buildingState: CurrentBuildingState = CurrentBuildingState()
    @State var uiContext: UiContext = UiContext()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(buildingState)
                .environment(uiContext)
        }
    }
}
