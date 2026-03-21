import SwiftUI

struct TodaySolarView: View {
    var peakProductionInW: Double
    var currentSolarProductionInW: Int
    var todaySolarProductionInWh: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Solar Production")
                .font(.subheadline)
                .fontWeight(.bold)

            Grid(alignment: .leadingFirstTextBaseline, verticalSpacing: 4) {
                GridRow {
                    Text("Current:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(
                        currentSolarProductionInW
                            .formatWattsAsKiloWatts(widthUnit: true)
                    )
                    .font(.caption)
                    .fontWeight(.bold)
                }

                GridRow {
                    Text("Peak:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(
                        peakProductionInW.formatAsKiloWatts(widthUnit: true)
                    )
                    .font(.caption)
                    .fontWeight(.bold)
                }

                GridRow {
                    Text("Total:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(
                        todaySolarProductionInWh
                            .formatWattHoursAsKiloWattsHours(widthUnit: true)
                    )
                    .font(.caption)
                    .fontWeight(.bold)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.yellow.opacity(0.12))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )
        )
    }
}

#Preview {
    VStack {
        TodaySolarView(
            peakProductionInW: 7539,
            currentSolarProductionInW: 6540,
            todaySolarProductionInWh: 23423
        )
        .frame(width: 180)
        .padding()

        Spacer()
    }
}
