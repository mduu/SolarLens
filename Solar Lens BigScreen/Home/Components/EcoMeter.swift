import SwiftUI

struct EcoMeter: View {
    var totalSolarProduction: Double

    private let co2PerWhInKg: Double = 0.00013
    private let boundCo2PerTreePerYearInKg: Double = 20

    private var avoidedCo2: Double {
        return totalSolarProduction / 10 * co2PerWhInKg
    }

    private var safedTrees: Double {
        return max(1, avoidedCo2 / boundCo2PerTreePerYearInKg)
    }

    var body: some View {
        VStack {
            Image(systemName: "leaf")
                .font(.system(size: 60))
                .foregroundStyle(.green)

            Text("\(safedTrees, specifier: "%.0f")")
                .font(.title3)


            Text("Trees planted")
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
