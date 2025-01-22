import AppIntents

struct GetSolarProductionIntent: AppIntent {
    static var title: LocalizedStringResource = "Get current solar production"
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Double> & ProvidesDialog {
        let solarManager = SolarManager.instance()
        let solarProduction = try? await solarManager.fetchOverviewData(
            lastOverviewData: nil)

        guard let solar = solarProduction?.currentSolarProduction else {
            throw IntentError.couldNotGetValue(
                "Could not get the current solar production")
        }
        
        let solarProductionKW = Double(solar / 1000)
        
        let dialog = IntentDialog(
            full: "The current solar production is \(solarProductionKW) kilo watts",
            systemImageName: "sun.max"
        )

        return .result(value: solarProductionKW, dialog: dialog)
    }
}
