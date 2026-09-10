import SwiftUI

struct EcoMeterCard: View {
    var totalProduction: Double

    @AppStorage(GridCarbonRegion.storageKey)
    private var storedGridRegion = GridCarbonRegion.fallback.rawValue

    private var impact: EcoImpact {
        EcoImpact(
            totalProductionWh: totalProduction,
            region: GridCarbonRegion(stored: storedGridRegion)
        )
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 32))
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 2) {
                Text("Same as \(impact.wholeTrees) trees")
                    .font(.title3)
                    .fontWeight(.semibold)

                Group {
                    if impact.showsCo2InTonnes {
                        Text("\(impact.avoidedCo2DisplayValue, specifier: "%.1f") t CO₂ avoided")
                    } else {
                        Text("\(impact.avoidedCo2DisplayValue, specifier: "%.1f") kg CO₂ avoided")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            EcoImpactInfoButton(impact: impact)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.green.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
    }
}
