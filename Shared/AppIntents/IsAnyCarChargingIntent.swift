import AppIntents

struct IsAnyCarChargingIntent: AppIntent {
    static var title: LocalizedStringResource = "Is any car charging?"
    static var description: IntentDescription? =
        "Returns 'true' if any car is currently charging, otherwise 'false'."

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> & ProvidesDialog {
        let solarManager = SolarManager.instance()
        let solarProduction = try? await solarManager.fetchOverviewData(
            lastOverviewData: nil)

        guard let isAnyCarCharging = solarProduction?.isAnyCarCharing else {
            throw IntentError.couldNotGetValue(
                "Could not retrieve if any car is charging")
        }

        let dialog = IntentDialog(
            full: isAnyCarCharging
                ? "A car is currently charging."
                : "No car is currently charging.",
            supporting:
                "I found this information in Solar Manager using Solar Lens",
            systemImageName: "bolt.car.circle"
        )

        return .result(value: isAnyCarCharging, dialog: dialog)
    }
}
