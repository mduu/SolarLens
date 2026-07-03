import SwiftUI

struct EcoMeterCard: View {
    var totalProduction: Double

    private var impact: EcoImpact {
        EcoImpact(totalProductionWh: totalProduction)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 32))
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(impact.equivalentTrees, specifier: "%.0f") Trees Saved")
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
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.green.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
    }
}
