import Charts
import SwiftUI

struct SolarDataPoint: Identifiable {
    let id = UUID()
    let time: Date
    let production: Double
}

struct SolarChart: View {

    @Binding var maxProductionkW: Double
    @Binding var solarProduction: ConsumptionData
    var isSmall: Bool = false

    var body: some View {
        let data =
            filterRelevantDataPoints(
                from:
                    solarProduction.data.map {
                        SolarDataPoint(
                            time: $0.date,
                            production: $0.productionWatts / 1000
                        )
                    }
            )

        Chart {
            ForEach(data) { dataPoint in
                AreaMark(
                    x: .value("Time", dataPoint.time),
                    y: .value("kW", dataPoint.production)
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

                LineMark(
                    x: .value("Time", dataPoint.time),
                    y: .value("kW", dataPoint.production)
                )
                .interpolationMethod(.cardinal)
                .lineStyle(
                    StrokeStyle(lineWidth: 1)
                )
            }  // :foreach
        }
        .chartYAxis {
            AxisMarks(preset: .automatic) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let number = value.as(Double.self) {
                        let max = data.map({ $0.production }).max() ?? 0
                        let min = data.map({ $0.production }).min() ?? 0
                        if !isSmall
                            || abs(min - number) < 0.2
                            || abs(max - number) < 0.2
                        {
                            Text("\(String(format: "%.1f", number))")
                        }
                    }
                }
            }
        }
        .chartYAxisLabel(isSmall ? "" : "kW")
        .chartYScale(domain: 0...getYMax())
        .chartXAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel(
                    format: .dateTime.hour(.twoDigits(amPM: .omitted)).minute()
                )
            }
        }
        .frame(maxHeight: .infinity)
        .foregroundColor(.yellow)

    }

    private func getTimeFormatter() -> DateFormatter {
        let result = DateFormatter()
        result.setLocalizedDateFormatFromTemplate("HH:mm")
        return result
    }

    private func getYMax() -> Double {
        let maxProduction: Double? = solarProduction.data
            .map { $0.productionWatts / 1000 }
            .max()

        guard let maxProduction else { return 2.0 }

        return maxProduction <= 0
            ? 2.0
            : maxProduction * 1.1
    }

    private func filterRelevantDataPoints(from dataPoints: [SolarDataPoint])
        -> [SolarDataPoint]
    {
        // Find first non-zero index
        var firstNonZeroIndex =
            dataPoints.firstIndex(where: { $0.production > 0 })
            ?? dataPoints.startIndex

        // Find last non-zero index, starting from the end
        var lastNonZeroIndex =
            dataPoints.lastIndex(where: { $0.production > 0 })
            ?? dataPoints.endIndex - 1

        if firstNonZeroIndex == lastNonZeroIndex {
            firstNonZeroIndex = dataPoints.startIndex
            lastNonZeroIndex = dataPoints.endIndex - 1
        }

        if firstNonZeroIndex > 0 {
            firstNonZeroIndex -= 1
        }

        if lastNonZeroIndex < dataPoints.endIndex - 1 {
            firstNonZeroIndex += 1
        }

        return Array(dataPoints[firstNonZeroIndex...lastNonZeroIndex])
    }
}

#Preview("Normal") {
    SolarChart(
        maxProductionkW: .constant(11000),
        solarProduction: .constant(ConsumptionData.fake())
    )
}

#Preview("Small") {
    SolarChart(
        maxProductionkW: .constant(11000),
        solarProduction: .constant(ConsumptionData.fake()),
        isSmall: true
    )
    .frame(height: 80)
}
