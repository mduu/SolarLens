import AppIntents

struct GetConsumptionIntent: AppIntent {
    static var title: LocalizedStringResource = "Get current consumption"

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Double> {
        let enegeryManager = SolarManager()
        let overview = try? await enegeryManager.fetchOverviewData(
            lastOverviewData: nil)

        guard let currentConsumption = overview?.currentOverallConsumption
        else {
            throw IntentError.couldNotGetValue(
                "Could not retrieve overall consumption")
        }

        return .result(
            value: Double(currentConsumption / 1000)
        )

    }
}
