import AppIntents
import Foundation

struct OpenOverview: AppIntent {
    static var title: LocalizedStringResource = "Open Solar Lens overview"
    static var description = IntentDescription(
        "Open Solar Lens and show the energy flow overview")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        buildingStateModel.selectedMainTab = MainTab.overview

        return .result()
    }

    @Dependency
    private var buildingStateModel: BuildingStateViewModel
}
