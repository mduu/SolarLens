import Charts
import SwiftUI

struct BatteryChart: View {
    let mainData: MainData
    let batteryHistory: [BatteryHistory]

    var body: some View {
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
    }
}
