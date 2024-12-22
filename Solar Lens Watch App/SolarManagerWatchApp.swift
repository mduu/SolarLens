import SwiftUI

@main
struct SolarManagerWatch_Watch_AppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    AppStoreReviewManager.shared.increaseStartupCount()
                }
        }
        .environment(\.locale, Locale(identifier: "DE"))
    }
}
