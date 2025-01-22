import AppIntents

struct GetConsumptionIntent: AppIntent {
    static var title: LocalizedStringResource = "Get current consumption"

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Double>
        & ProvidesDialog
    {
        let solarManager = SolarManager.instance()
        let overview = try? await solarManager.fetchOverviewData(
            lastOverviewData: nil)

        guard let currentConsumption = overview?.currentOverallConsumption
        else {
            throw IntentError.couldNotGetValue(
                "Could not retrieve overall consumption")
        }
        
        let consumptionKW = Double(currentConsumption) / 1000

        let dialog = IntentDialog(
            full: "The current overall consumption is \(String(format: "%.1f", consumptionKW)) kilowatts",
            systemImageName: "house"
        )

        return .result(
            value: Double(currentConsumption / 1000),
            dialog: dialog
        )

    }
}
