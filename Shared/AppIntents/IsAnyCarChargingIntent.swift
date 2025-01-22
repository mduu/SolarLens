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
                ? LocalizedStringResource("A car is currently charging.")
                : LocalizedStringResource("No car is currently charging."),
            systemImageName: "bolt.car.circle"
        )

        return .result(value: isAnyCarCharging, dialog: dialog)
    }
}
