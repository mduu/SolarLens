import Charts
import SwiftUI

struct OverviewChart: View {

    @Binding var consumption: ConsumptionData
    var isSmall: Bool = false
    var isAccent: Bool = false

    var body: some View {

        Chart {
            ForEach(consumption.data) { dataPoint in

                if !isAccent {
                    AreaMark(
                        x: .value("Time", dataPoint.date),
                        y: .value("kW", dataPoint.productionWatts / 1000),
                        stacking: .unstacked
                    )
                    .interpolationMethod(.cardinal)
                    .foregroundStyle(
                        .linearGradient(
                            colors: [
                                .yellow.opacity(0.5),
                                .yellow.opacity(0.1),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .lineStyle(
                        StrokeStyle(lineWidth: 0)
                    )
                    .foregroundStyle(by: .value("Series", "Production"))

                }

                LineMark(
                    x: .value("Time", dataPoint.date),
                    y: .value("kW", dataPoint.productionWatts / 1000)
                )
                .foregroundStyle(by: .value("Series", "Production"))
                .interpolationMethod(.cardinal)
                .lineStyle(
                    StrokeStyle(lineWidth: 1)
                )

                // -- Consumption --

                if !isAccent {
                    AreaMark(
                        x: .value("Time", dataPoint.date),
                        y: .value("kW", dataPoint.consumptionWatts / 1000),
                        stacking: .unstacked
                    )
                    .interpolationMethod(.cardinal)
                    .foregroundStyle(
                        .linearGradient(
                            colors: [
                                .teal.opacity(0.5),
                                .teal.opacity(0.1),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .lineStyle(
                        StrokeStyle(lineWidth: 0)
                    )
                    .foregroundStyle(by: .value("Series", "Consumption"))
                }

                LineMark(
                    x: .value("Time", dataPoint.date),
                    y: .value("kW", dataPoint.consumptionWatts / 1000)
                )
                .foregroundStyle(by: .value("Series", "Consumption"))
                .interpolationMethod(.cardinal)
                .lineStyle(
                    StrokeStyle(lineWidth: 1, dash: isAccent ? [2, 2] : [])
                )

            }  // :foreach
        }
        .chartYAxis {
            AxisMarks(preset: .automatic) { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartYAxisLabel(isSmall ? "" : "kW")
        .chartYScale(domain: 0...getYMax())
        .chartXAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel(
                    format: .dateTime.hour(.twoDigits(amPM: .omitted)).minute(
                        .twoDigits)
                )
            }
        }
        .chartForegroundStyleScale([
            "Production": .yellow,
            "Consumption": Color.teal,
        ])
        .chartLegend(isSmall ? .hidden : .visible)
        .frame(maxHeight: .infinity)
    }

    private func getTimeFormatter() -> DateFormatter {
        let result = DateFormatter()
        result.setLocalizedDateFormatFromTemplate("HH:mm")
        return result
    }

    private func getYMax() -> Double {
        let maxkW: Double? = consumption.data
            .map { max($0.productionWatts, $0.consumptionWatts) / 1000 }
            .max()

        guard let maxkW else { return 2.0 }

        return maxkW <= 0.005
            ? 2.0
            : maxkW * 1.1
    }

}

#Preview("Normal") {
    OverviewChart(
        consumption: .constant(ConsumptionData.fake())
    )
}

#Preview("Small") {
    OverviewChart(
        consumption: .constant(ConsumptionData.fake()),
        isSmall: true
    )
    .frame(height: 80)
}
