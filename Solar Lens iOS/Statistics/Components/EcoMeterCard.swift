import SwiftUI

struct EcoMeterCard: View {
    var totalProduction: Double

    private let co2PerWhInKg: Double = 0.00013
    private let boundCo2PerTreePerYearInKg: Double = 20

    private var avoidedCo2: Double {
        totalProduction / 10 * co2PerWhInKg
    }

    private var savedTrees: Double {
        max(1, avoidedCo2 / boundCo2PerTreePerYearInKg)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 32))
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(savedTrees, specifier: "%.0f") Trees Saved")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("\(avoidedCo2, specifier: "%.1f") kg CO₂ avoided")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.green.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
    }
}
