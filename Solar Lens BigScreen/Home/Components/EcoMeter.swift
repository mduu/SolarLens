import SwiftUI

struct EcoMeter: View {
    var totalSolarProduction: Double

    private var treeEquivalent: Double {
        EcoImpact(totalProductionWh: totalSolarProduction).equivalentTrees
    }

    var body: some View {
        VStack {
            Image(systemName: "leaf")
                .font(.system(size: 60))
                .foregroundStyle(.green)

            Text("\(treeEquivalent, specifier: "%.0f")")
                .font(.title3)


            Text("Tree equivalent")
                .font(.caption2)
                .foregroundStyle(.secondary)

        }
    }
}

#Preview {
    EcoMeter(
        totalSolarProduction: 11_500_000
    )
    .frame(width: 150, height: 150)
}
