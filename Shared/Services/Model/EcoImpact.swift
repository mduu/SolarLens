/// CO₂-avoidance figures derived from the total solar production.
///
/// Uses the same coefficients as Huawei FusionSolar (SmartPVMS) so the numbers
/// match the manufacturer app: 1 kWh of solar energy avoids 475 g CO₂ (IEA
/// global average) and one tree binds 18.3 kg CO₂ per year over a 40-year
/// lifespan.
struct EcoImpact {
    /// Avoided CO₂ per Wh of production, in kg (= 0.475 kg/kWh).
    private static let avoidedCo2PerWhInKg = 0.000475

    /// CO₂ bound by one tree over its lifetime: 18.3 kg/year × 40 years.
    private static let boundCo2PerTreeInKg = 18.3 * 40

    /// Total avoided CO₂ in kg.
    let avoidedCo2InKg: Double

    /// Number of trees it would take to bind the same amount of CO₂.
    let equivalentTrees: Double

    init(totalProductionWh: Double) {
        avoidedCo2InKg = totalProductionWh * Self.avoidedCo2PerWhInKg
        equivalentTrees = max(1, avoidedCo2InKg / Self.boundCo2PerTreeInKg)
    }

    /// True when the CO₂ amount is better displayed in tonnes than kg.
    var showsCo2InTonnes: Bool { avoidedCo2InKg >= 1000 }

    /// The CO₂ amount in the display unit: kg below one tonne, tonnes above.
    var avoidedCo2DisplayValue: Double {
        showsCo2InTonnes ? avoidedCo2InKg / 1000 : avoidedCo2InKg
    }
}
