internal import Foundation

/// Shared formulas for the two efficiency headline numbers so the home card,
/// the Efficiency sheet, and the battery simulator all agree.
enum EnergyEfficiency {

    /// Self-consumption rate: share of produced energy consumed on-site (%).
    static func selfConsumptionRate(production: Double, selfConsumption: Double) -> Double {
        guard production > 0 else { return 0 }
        return min(max(selfConsumption / production * 100, 0), 100)
    }

    /// Autarky / self-sufficiency: share of consumption covered by own production (%).
    static func autarky(consumption: Double, selfConsumption: Double) -> Double {
        guard consumption > 0 else { return 0 }
        return min(max(selfConsumption / consumption * 100, 0), 100)
    }
}
