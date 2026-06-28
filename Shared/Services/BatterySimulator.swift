internal import Foundation

/// Tunable inputs for the virtual battery "what-if" simulation.
struct BatterySimulationParameters {
    /// Usable capacity in kWh.
    var capacityKwh: Double
    /// Maximum charge/discharge power in kW (symmetric).
    var maxPowerKw: Double
    /// Round-trip efficiency as a fraction (0–1), applied on discharge.
    var roundTripEfficiency: Double
    /// Minimum state of charge as a fraction (0–1); the battery never
    /// discharges below this reserve.
    var minStateOfCharge: Double

    /// Fixed minimum state-of-charge reserve used for now (5%). Surfaced to
    /// the user on the simulator for transparency.
    static let defaultMinStateOfCharge = 0.05
    static let defaultMaxPowerKw = 7.0
    static let defaultRoundTripEfficiency = 0.90

    init(
        capacityKwh: Double,
        maxPowerKw: Double = BatterySimulationParameters.defaultMaxPowerKw,
        roundTripEfficiency: Double = BatterySimulationParameters.defaultRoundTripEfficiency,
        minStateOfCharge: Double = BatterySimulationParameters.defaultMinStateOfCharge
    ) {
        self.capacityKwh = capacityKwh
        self.maxPowerKw = maxPowerKw
        self.roundTripEfficiency = roundTripEfficiency
        self.minStateOfCharge = minStateOfCharge
    }
}

/// Outcome of replaying a series of interval samples through a virtual battery.
struct BatterySimulationResult: Identifiable {
    let id = UUID()
    let capacityKwh: Double

    /// Grid import avoided by discharging the battery, in Wh.
    let avoidedImportWh: Double
    /// Grid export forgone because surplus charged the battery instead, in Wh.
    let reducedExportWh: Double

    /// Net money saved in main currency units (avoided import cost minus the
    /// forgone export revenue spent charging the battery).
    let netSavings: Double

    /// Value of the grid import avoided, in main currency units.
    let avoidedImportValue: Double
    /// Feed-in revenue forgone by charging the battery, in main currency units.
    let forgoneExportValue: Double

    /// Effective (energy-weighted) import rate actually applied, in main
    /// currency per kWh — surfaced for transparency.
    var effectiveImportRate: Double {
        avoidedImportWh > 0 ? avoidedImportValue / (avoidedImportWh / 1000) : 0
    }
    /// Effective feed-in rate actually applied, in main currency per kWh.
    var effectiveFeedInRate: Double {
        reducedExportWh > 0 ? forgoneExportValue / (reducedExportWh / 1000) : 0
    }

    let autarkyWithout: Double          // %
    let autarkyWith: Double             // %
    let selfConsumptionWithout: Double  // %
    let selfConsumptionWith: Double     // %

    var autarkyImprovement: Double { autarkyWith - autarkyWithout }
    var selfConsumptionImprovement: Double { selfConsumptionWith - selfConsumptionWithout }
}

/// Replays measured production/consumption data through a virtual battery to
/// estimate the savings and efficiency gains a battery *would* have delivered.
///
/// Greedy per-interval dispatch: surplus that was exported to the grid charges
/// the battery; deficit that was imported from the grid is covered by
/// discharging it. This deliberately captures only "store surplus, cover load"
/// — a real owner can do better (e.g. discharging to the EV before leaving so
/// the battery can buffer more PV, tariff arbitrage), so the result is a
/// **conservative lower bound**.
enum BatterySimulator {

    static func simulate(
        data: [MainDataItem],
        parameters: BatterySimulationParameters,
        tariffSettings: TariffSettingsV3Response?,
        fallbackTariff: TariffV1Response?,
        dynamicImport: DynamicTariff? = nil
    ) -> BatterySimulationResult {
        let sorted = data.sorted { $0.date < $1.date }

        let capacityWh = max(parameters.capacityKwh, 0) * 1000
        let floorWh = capacityWh * min(max(parameters.minStateOfCharge, 0), 1)
        let efficiency = min(max(parameters.roundTripEfficiency, 0.01), 1)
        let intervalHours = medianIntervalSeconds(of: sorted) / 3600
        let maxStepWh = max(parameters.maxPowerKw, 0) * 1000 * intervalHours

        var soc = floorWh  // start empty (at the reserve floor)
        var avoidedImportWh = 0.0
        var reducedExportWh = 0.0
        var avoidedImportValue = 0.0
        var forgoneExportValue = 0.0

        for item in sorted {
            // Charge from surplus (energy that was exported to the grid).
            let surplus = max(item.exportedOverTimeWhatthours, 0)
            let room = max(capacityWh - soc, 0)
            let charged = min(surplus, maxStepWh, room)
            if charged > 0 {
                soc += charged
                reducedExportWh += charged
                let exportRate = TariffCalculator.exportRateCHF(
                    at: item.date, tariffSettings: tariffSettings, fallbackTariff: fallbackTariff
                )
                forgoneExportValue += (charged / 1000) * exportRate  // forgone export revenue
            }

            // Discharge to cover deficit (energy that was imported from the grid).
            let deficit = max(item.importedOverTimeWhatthours, 0)
            let drawable = max(soc - floorWh, 0)
            let delivered = min(deficit, maxStepWh, drawable * efficiency)
            if delivered > 0 {
                soc -= delivered / efficiency
                avoidedImportWh += delivered
                let importRate = TariffCalculator.importRateCHF(
                    at: item.date, dynamicImport: dynamicImport,
                    tariffSettings: tariffSettings, fallbackTariff: fallbackTariff
                )
                avoidedImportValue += (delivered / 1000) * importRate  // avoided import cost
            }
        }

        let totalConsumption = sorted.reduce(0.0) { $0 + $1.consumptionOverTimeWatthours }
        let totalProduction = sorted.reduce(0.0) { $0 + $1.productionOverTimeWatthours }
        let totalImport = sorted.reduce(0.0) { $0 + $1.importedOverTimeWhatthours }

        let selfConsumedWithout = max(totalConsumption - totalImport, 0)
        let selfConsumedWith = selfConsumedWithout + avoidedImportWh

        return BatterySimulationResult(
            capacityKwh: parameters.capacityKwh,
            avoidedImportWh: avoidedImportWh,
            reducedExportWh: reducedExportWh,
            netSavings: avoidedImportValue - forgoneExportValue,
            avoidedImportValue: avoidedImportValue,
            forgoneExportValue: forgoneExportValue,
            autarkyWithout: EnergyEfficiency.autarky(consumption: totalConsumption, selfConsumption: selfConsumedWithout),
            autarkyWith: EnergyEfficiency.autarky(consumption: totalConsumption, selfConsumption: selfConsumedWith),
            selfConsumptionWithout: EnergyEfficiency.selfConsumptionRate(production: totalProduction, selfConsumption: selfConsumedWithout),
            selfConsumptionWith: EnergyEfficiency.selfConsumptionRate(production: totalProduction, selfConsumption: selfConsumedWith)
        )
    }

    /// Median spacing between samples, used to cap per-interval throughput.
    /// Falls back to one hour when it cannot be derived.
    private static func medianIntervalSeconds(of sorted: [MainDataItem]) -> Double {
        guard sorted.count >= 2 else { return 3600 }
        var deltas: [Double] = []
        for i in 1..<sorted.count {
            let d = sorted[i].date.timeIntervalSince(sorted[i - 1].date)
            if d > 0 { deltas.append(d) }
        }
        guard !deltas.isEmpty else { return 3600 }
        deltas.sort()
        return deltas[deltas.count / 2]
    }
}
