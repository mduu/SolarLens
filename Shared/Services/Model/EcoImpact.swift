/// CO₂-avoidance figures derived from the total solar production.
///
/// A tree binds 18.3 kg CO₂ per year over a 40-year lifespan; those two
/// coefficients, and the 475 g/kWh global average behind
/// `GridCarbonRegion.international`, match the manufacturer app's, so a system
/// shows the same number in both as long as the global average is selected.
struct EcoImpact {
    /// CO₂ bound by one tree in a year, in kg.
    static let boundCo2PerTreePerYearInKg = 18.3

    /// The tree lifespan the comparison is based on, in years.
    static let treeLifespanInYears = 40.0

    /// CO₂ bound by one tree over its lifetime: 18.3 kg/year × 40 years.
    static let boundCo2PerTreeInKg =
        boundCo2PerTreePerYearInKg * treeLifespanInYears

    /// The grid this production is credited against.
    let region: GridCarbonRegion

    /// Avoided CO₂ per Wh of production, in kg — the region's factor.
    let avoidedCo2PerWhInKg: Double

    /// Total avoided CO₂ in kg.
    let avoidedCo2InKg: Double

    /// Number of trees it would take to bind the same amount of CO₂.
    let equivalentTrees: Double

    /// The production the figures were derived from, so an explanation can
    /// show the reader their own numbers rather than a general formula.
    let totalProductionWh: Double

    init(totalProductionWh: Double, region: GridCarbonRegion = .fallback) {
        self.totalProductionWh = totalProductionWh
        self.region = region
        avoidedCo2PerWhInKg = region.avoidedCo2PerWhInKg
        avoidedCo2InKg = totalProductionWh * avoidedCo2PerWhInKg
        equivalentTrees = max(1, avoidedCo2InKg / Self.boundCo2PerTreeInKg)
    }

    /// The figure as shown: a whole number, so a label can be pluralised.
    /// On a clean grid this really does reach 1, and "1 trees" is wrong in
    /// every language we ship.
    var wholeTrees: Int { Int(equivalentTrees.rounded()) }

    /// True when the CO₂ amount is better displayed in tonnes than kg.
    var showsCo2InTonnes: Bool { avoidedCo2InKg >= 1000 }

    /// The CO₂ amount in the display unit: kg below one tonne, tonnes above.
    var avoidedCo2DisplayValue: Double {
        showsCo2InTonnes ? avoidedCo2InKg / 1000 : avoidedCo2InKg
    }
}
