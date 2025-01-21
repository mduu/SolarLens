import AppIntents

struct GetSolarProductionIntent: AppIntent {
    static var title: LocalizedStringResource = "Get current solar production"
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Double> {
        let solarManager = SolarManager.instance()
        let solarProduction = try? await solarManager.fetchOverviewData(
            lastOverviewData: nil)

        guard let solar = solarProduction?.currentSolarProduction else {
            throw IntentError.couldNotGetValue(
                "Could not get the current solar production")
        }

        return .result(value: Double(solar / 1000))
    }
}
