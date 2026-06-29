import SwiftUI

/// Loads the data behind the battery advantage report for a selectable period
/// (today / week / month / year). Fetches the period's interval data (chunked
/// monthly for long ranges) plus the period statistics and tariffs, so the
/// advantage card can show savings, autarky, and self-consumption over the
/// chosen period instead of only today.
@MainActor
@Observable
class BatteryAdvantageViewModel {
    var mainData: MainData?
    var tariff: TariffV1Response?
    var tariffSettings: TariffSettingsV3Response?
    var dynamicTariff: DynamicTariff?

    var consumptionWh: Double = 0
    var productionWh: Double = 0
    var autarkyPercent: Double = 0
    var selfConsumptionPercent: Double = 0

    var isLoading = false

    private let energyManager: EnergyManager

    init(energyManager: EnergyManager = SolarManager.shared) {
        self.energyManager = energyManager
    }

    func fetch(period: EfficiencyPeriod) async {
        if isLoading { return }
        isLoading = true
        defer { isLoading = false }

        let range = period.range()
        let days = Calendar.current.dateComponents([.day], from: range.from, to: range.to).day ?? 0
        // Cap at hourly: time-of-use rates are resolved per sample timestamp,
        // so daily samples would price a whole day's discharge at the midnight
        // tariff slot and distort the savings. Hourly keeps it meaningful.
        let interval = days <= 7 ? 300 : 3600

        // Tariffs + statistics in parallel.
        async let fallbackTask = try? energyManager.fetchTariff()
        async let settingsTask = try? energyManager.fetchDetailedTariffs()
        async let dynamicTask = try? energyManager.fetchDynamicTariff()
        async let statsTask = try? energyManager.fetchStatistics(
            from: range.from, to: range.to, accuracy: range.accuracy
        )

        // Interval data, chunked monthly to keep requests small.
        let chunks = DateRangeChunker.monthlyChunks(from: range.from, to: range.to)
        var items: [MainDataItem] = []
        for chunk in chunks {
            if let chunkData = try? await energyManager.fetchMainData(
                from: chunk.start, to: chunk.end, interval: interval
            ) {
                items.append(contentsOf: chunkData.data)
            }
        }
        mainData = MainData(data: items)

        let (fallbackTariff, settings, dynamic, stats) = await (fallbackTask, settingsTask, dynamicTask, statsTask)
        tariff = fallbackTariff
        tariffSettings = settings
        dynamicTariff = DynamicTariff(dynamic)

        let production = stats?.production ?? 0
        let consumption = stats?.consumption ?? 0
        let selfConsumption = stats?.selfConsumption ?? 0
        productionWh = production
        consumptionWh = consumption
        // Prefer the server-provided rates; the raw selfConsumption field isn't
        // reliable for aggregated (week/month/year) periods.
        autarkyPercent = stats?.autarchyDegree
            ?? EnergyEfficiency.autarky(consumption: consumption, selfConsumption: selfConsumption)
        selfConsumptionPercent = stats?.selfConsumptionRate
            ?? EnergyEfficiency.selfConsumptionRate(production: production, selfConsumption: selfConsumption)
    }
}
