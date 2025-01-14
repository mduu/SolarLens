import AppIntents

struct GetBatteryLevelIntent : AppIntent {
    static var title: LocalizedStringResource = "Get current battery level"

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Double> {
        let enegeryManager = SolarManager()
        let solarProduction = try? await enegeryManager.fetchOverviewData(lastOverviewData: nil)
        
        if let batteryLevel = solarProduction?.currentBatteryLevel {
            return .result(
                value: Double(batteryLevel / 1000)
            )
        }
        
        throw IntentError.couldNotGetValue("Could not retrieve battery level")
    }
}
