internal import Foundation

extension DayStatistic {
    /// The part of the bucket's consumption that did not come from the grid.
    var ownConsumption: Double { max(0, consumption - imported) }

    /// The part of the bucket's production that was not fed into the grid.
    var keptProduction: Double { max(0, production - exported) }

    /// Share of consumption the house covered itself, in percent. `nil` for a
    /// bucket without consumption — there is nothing to be autark about.
    var autarky: Double? {
        guard consumption > 0 else { return nil }
        return EnergyEfficiency.autarky(
            consumption: consumption, selfConsumption: ownConsumption
        )
    }

    /// Share of production that stayed in the house rather than going to the
    /// grid, in percent. `nil` for a bucket without production.
    var selfConsumptionRate: Double? {
        guard production > 0 else { return nil }
        return EnergyEfficiency.selfConsumptionRate(
            production: production, selfConsumption: keptProduction
        )
    }

    /// The two buckets' figures added up, filed under this one's date.
    func adding(_ other: DayStatistic) -> DayStatistic {
        DayStatistic(
            day: day,
            consumption: consumption + other.consumption,
            production: production + other.production,
            imported: imported + other.imported,
            exported: exported + other.exported,
            batteryCharged: batteryCharged + other.batteryCharged,
            batteryDischarged: batteryDischarged + other.batteryDischarged
        )
    }
}
