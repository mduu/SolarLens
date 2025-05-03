import AppIntents

struct EfficiencyInfo: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "Todays efficiency"
    )
    static var defaultQuery = EfficiencyInfoQuery()

    @Property var id: String
    @Property var selfConsumptionPercent: Double?
    @Property var autarkyPercent: Double?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "Efficiency",
            subtitle:
                "Self-consumption: \(selfConsumptionPercent ?? 0)% and autarky: \(autarkyPercent ?? 0)%"
        )
    }
}

struct EfficiencyInfoQuery: EntityQuery {

    func entities(for identifiers: [String]) async -> [EfficiencyInfo] {
        return try! await suggestedEntities()
    }

    func suggestedEntities() async throws -> [EfficiencyInfo] {
        // Provide example or default entities (if needed)
        let solarManager = SolarManager.instance()
        let overview = try? await solarManager.fetchOverviewData(
            lastOverviewData: nil
        )

        let selfConsumption = overview?.todaySelfConsumptionRate ?? 0
        let autarky = overview?.todayAutarchyDegree ?? 0

        let efficiency = EfficiencyInfo()
        efficiency.id = "1"
        efficiency.selfConsumptionPercent = selfConsumption
        efficiency.autarkyPercent = autarky

        return [efficiency]
    }
}

struct GetEfficiencyIntent: AppIntent {
    static var title: LocalizedStringResource =
        "Get efficiency"
    static var description: IntentDescription? =
        "Information about our site efficiency"

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<EfficiencyInfo> & ProvidesDialog
    {
        let efficiencies = try? await EfficiencyInfoQuery().suggestedEntities()
        let efficiency = efficiencies?.first ?? EfficiencyInfo()
        
        let dialog = IntentDialog(
            full:
                LocalizedStringResource(
                    "The efficiency is \(efficiency.selfConsumptionPercent.formatIntoPercentage()) self-consumption and \(efficiency.autarkyPercent.formatIntoPercentage()) autarky."
                ),
            systemImageName:
                "gauge.open.with.lines.needle.33percent.and.arrow.trianglehead.from.0percent.to.50percent"
        )

        return .result(value: efficiency, dialog: dialog)
    }
}
