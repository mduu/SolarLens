import SwiftUI

/// Period choices for the Efficiency sheet, expressed as relative day spans
/// (today / last 7 / 30 / 365 days). Mirrors the efficiency story in one place
/// instead of being spread across separate Statistics tabs.
enum EfficiencyPeriod: String, CaseIterable, Identifiable {
    case today
    case days7 = "7d"
    case days30 = "30d"
    case days365 = "365d"

    var id: String { rawValue }

    var localizedName: LocalizedStringKey {
        switch self {
        case .today: "Today"
        case .days7: "7d"
        case .days30: "30d"
        case .days365: "365d"
        }
    }

    /// Resolves the date range and the appropriate aggregation accuracy.
    func range() -> (from: Date, to: Date, accuracy: Accuracy) {
        let calendar = Calendar.current
        switch self {
        case .today:
            return (Date.todayStartOfDay(), Date.todayEndOfDay(), .high)
        case .days7:
            let start = calendar.date(byAdding: .day, value: -7, to: Date.todayStartOfDay())!
            return (start, Date(), .medium)
        case .days30:
            let start = calendar.date(byAdding: .day, value: -30, to: Date.todayStartOfDay())!
            return (start, Date(), .medium)
        case .days365:
            let start = calendar.date(byAdding: .day, value: -365, to: Date.todayStartOfDay())!
            return (start, Date(), .low)
        }
    }
}

@MainActor
@Observable
class EfficiencyViewModel {
    var selectedPeriod: EfficiencyPeriod = .today

    var autarkyPercent: Double?
    var selfConsumptionPercent: Double?
    var productionWh: Double = 0
    var consumptionWh: Double = 0
    var gridImportWh: Double = 0
    var gridExportWh: Double = 0
    var isLoading = false

    private let energyManager: EnergyManager

    init(energyManager: EnergyManager = SolarManager.shared) {
        self.energyManager = energyManager
    }

    func fetch() async {
        if isLoading { return }
        isLoading = true
        defer { isLoading = false }

        let range = selectedPeriod.range()

        guard let stats = try? await energyManager.fetchStatistics(
            from: range.from,
            to: range.to,
            accuracy: range.accuracy
        ) else {
            autarkyPercent = nil
            selfConsumptionPercent = nil
            return
        }

        let production = stats.production ?? 0
        let consumption = stats.consumption ?? 0
        let selfConsumption = stats.selfConsumption ?? 0

        productionWh = production
        consumptionWh = consumption
        gridImportWh = max(0, consumption - selfConsumption)
        gridExportWh = max(0, production - selfConsumption)
        autarkyPercent = EnergyEfficiency.autarky(consumption: consumption, selfConsumption: selfConsumption)
        selfConsumptionPercent = EnergyEfficiency.selfConsumptionRate(production: production, selfConsumption: selfConsumption)
    }
}
