import SwiftUI

struct TodayConsumptionView: View {
    var peakConsumptionInW: Double
    var currentConsumptionInW: Int
    var todayConsumptionInWh: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Consumption")
                .font(.subheadline)
                .fontWeight(.bold)

            Grid(alignment: .leadingFirstTextBaseline, verticalSpacing: 4) {
                GridRow {
                    Text("Current:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(
                        currentConsumptionInW
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
                        peakConsumptionInW.formatAsKiloWatts(widthUnit: true)
                    )
                    .font(.caption)
                    .fontWeight(.bold)
                }

                GridRow {
                    Text("Total:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(
                        todayConsumptionInWh
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
                .fill(.ultraThinMaterial)
        )
    }
}

#Preview {
    VStack {
        TodayConsumptionView(
            peakConsumptionInW: 7539,
            currentConsumptionInW: 6540,
            todayConsumptionInWh: 23423
        )
        .frame(width: 180)
        .padding()

        Spacer()
    }
}
