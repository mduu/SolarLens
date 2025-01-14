import AppIntents
import SwiftUI

struct GetSolarProductionIntent : AppIntent {
    static var title: LocalizedStringResource = "Get current solar production"

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Double> {
        let enegeryManager = SolarManager()
        let solarProduction = try? await enegeryManager.fetchOverviewData(lastOverviewData: nil)
        
        if solarProduction == nil {
            throw IntentError.couldNotGetValue("Could not get the current solar production")
        }
        
        return .result(value: Double(solarProduction!.currentSolarProduction / 1000))
    }
}
