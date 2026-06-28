import SwiftUI

/// Drives the "What if I had a battery?" simulation: fetches a year of the
/// user's own production/consumption (chunked monthly with progress), then
/// replays it through `BatterySimulator` for a custom capacity and a preset
/// size sweep, valuing the result with the user's real tariffs.
@MainActor
@Observable
class BatteryWhatIfViewModel {
    var selectedYear: Int
    var customCapacityKwh: Double = 10
    var maxPowerKw: Double = BatterySimulationParameters.defaultMaxPowerKw
    var roundTripEfficiencyPercent: Double = BatterySimulationParameters.defaultRoundTripEfficiency * 100

    /// Preset capacities for the comparison sweep (helps find the minimum
    /// sensible size by showing diminishing returns).
    let presetCapacities: [Double] = [5, 10, 15]

    var isRunning = false
    var progress: Double = 0
    var hasRun = false
    var errorMessage: LocalizedStringKey?

    var customResult: BatterySimulationResult?
    var sweepResults: [BatterySimulationResult] = []

    let availableYears: [Int]
    let minStateOfChargePercent = Int((BatterySimulationParameters.defaultMinStateOfCharge * 100).rounded())

    private let energyManager: EnergyManager

    init(energyManager: EnergyManager = SolarManager.shared) {
        self.energyManager = energyManager
        let currentYear = Calendar.current.component(.year, from: Date())
        // Default to the last *full* calendar year; offer a handful back.
        self.selectedYear = currentYear - 1
        self.availableYears = Array((currentYear - 5)...currentYear).reversed()
    }

    func run() async {
        if isRunning { return }
        isRunning = true
        progress = 0
        errorMessage = nil
        defer { isRunning = false }

        let calendar = Calendar.current
        var startComponents = DateComponents()
        startComponents.year = selectedYear
        startComponents.month = 1
        startComponents.day = 1
        guard let yearStart = calendar.date(from: startComponents) else {
            errorMessage = "Could not determine the selected year."
            return
        }
        var endComponents = DateComponents()
        endComponents.year = selectedYear + 1
        endComponents.month = 1
        endComponents.day = 1
        let yearEnd = min(calendar.date(from: endComponents) ?? Date(), Date())

        guard yearStart < yearEnd else {
            errorMessage = "The selected year is in the future."
            return
        }

        // Tariffs (once for the whole run).
        async let fallbackTask = try? energyManager.fetchTariff()
        async let settingsTask = try? energyManager.fetchDetailedTariffs()
        async let dynamicTask = try? energyManager.fetchDynamicTariff()
        let (fallbackTariff, tariffSettings, dynamicResponse) = await (fallbackTask, settingsTask, dynamicTask)
        let dynamicImport = DynamicTariff(dynamicResponse)

        // Chunked monthly fetch at hourly resolution.
        let chunks = DateRangeChunker.monthlyChunks(from: yearStart, to: yearEnd)
        var data: [MainDataItem] = []
        for (index, chunk) in chunks.enumerated() {
            if let chunkData = try? await energyManager.fetchMainData(
                from: chunk.start,
                to: chunk.end,
                interval: 3600
            ) {
                data.append(contentsOf: chunkData.data)
            }
            progress = Double(index + 1) / Double(max(chunks.count, 1))
        }

        guard !data.isEmpty else {
            errorMessage = "No data available for the selected year."
            return
        }

        let efficiency = roundTripEfficiencyPercent / 100

        func makeParameters(_ capacity: Double) -> BatterySimulationParameters {
            BatterySimulationParameters(
                capacityKwh: capacity,
                maxPowerKw: maxPowerKw,
                roundTripEfficiency: efficiency
            )
        }

        sweepResults = presetCapacities.map { capacity in
            BatterySimulator.simulate(
                data: data,
                parameters: makeParameters(capacity),
                tariffSettings: tariffSettings,
                fallbackTariff: fallbackTariff,
                dynamicImport: dynamicImport
            )
        }
        customResult = BatterySimulator.simulate(
            data: data,
            parameters: makeParameters(customCapacityKwh),
            tariffSettings: tariffSettings,
            fallbackTariff: fallbackTariff,
            dynamicImport: dynamicImport
        )
        hasRun = true
    }
}
