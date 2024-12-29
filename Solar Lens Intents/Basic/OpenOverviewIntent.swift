import AppIntents
import Foundation

struct OpenOverviewIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Solar Lens overview"
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        buildingStateModel.selectedMainTab = MainTab.overview

        return .result()
    }

    @Dependency
    private var buildingStateModel: BuildingStateViewModel
}
