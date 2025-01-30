import SwiftUI

@main
struct SolarManagerWatch_Watch_AppApp: App {
    @State var currentBuildingState = CurrentBuildingState(energyManagerClient: SolarManager.instance())
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    AppStoreReviewManager.shared.increaseStartupCount()
                }
                .environment(currentBuildingState)
        }
        //.environment(\.locale, Locale(identifier: "DE"))
    }
}
