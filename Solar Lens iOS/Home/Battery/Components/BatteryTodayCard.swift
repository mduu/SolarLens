import Charts
import SwiftUI

struct BatteryTodayCard: View {
    let mainData: MainData?
    let batteryHistory: [BatteryHistory]?

    var body: some View {
        let totalCharged = mainData?.data.reduce(0.0) { $0 + $1.batteryChargedWh } ?? 0
        let totalDischarged = mainData?.data.reduce(0.0) { $0 + $1.batteryDischargedWh } ?? 0

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.7))
                Text("Today")
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.7))
            }

            // Totals
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.caption)
                        .foregroundStyle(.purple)
                    Text("Charged:")
                        .font(.caption)
                        .foregroundStyle(.primary.opacity(0.7))
                    Text(totalCharged.formatWattHoursAsKiloWattsHours(widthUnit: true))
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.caption)
                        .foregroundStyle(.indigo)
                    Text("Discharged:")
                        .font(.caption)
                        .foregroundStyle(.primary.opacity(0.7))
                    Text(totalDischarged.formatWattHoursAsKiloWattsHours(widthUnit: true))
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                Spacer()
            }

            // Chart
            if let mainData, let batteryHistory, !batteryHistory.isEmpty {
                let maxkW = batteryHistory
                    .flatMap { $0.items }
                    .map { max($0.averagePowerChargedW, $0.averagePowerDischargedW) / 1000 }
                    .max() ?? 2.0

                Chart {
                    BatterySeries(
                        batteries: batteryHistory,
                        isAccent: false,
                        batteryConsumptionLabel: String(localized: "Discharged"),
                        batteryChargedLabel: String(localized: "Charged")
                    )

                    if mainData.data.contains(where: { $0.batteryLevel != nil }) {
                        BatteryLevelSeries(
                            data: mainData.data,
                            maxY: max(maxkW * 1.1, 0.5),
                            isAccent: false,
                            batteryLabel: String(localized: "Level")
                        )
                    }
                }
                .chartYScale(domain: 0...max(maxkW * 1.1, 0.5))
                .chartYAxis {
                    AxisMarks(preset: .automatic) { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .chartYAxisLabel("kW")
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisValueLabel(
                            format: .dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)
                        )
                    }
                }
                .chartLegend(.visible)
                .chartLegend(spacing: 4)
                .chartForegroundStyleScale([
                    String(localized: "Discharged"): Color.indigo,
                    String(localized: "Charged"): Color.purple,
                    String(localized: "Level"): SerieColors.batteryLevelColor(useAlternativeColors: false),
                ])
                .frame(height: 180)
            } else if mainData == nil {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}
