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
                LineMark(
                    x: .value("Time", dataPoint.time),
                    y: .value("kW", dataPoint.production)
                )
                .interpolationMethod(.cardinal)
            }
        }
        .chartYAxisLabel("kW")
        .chartYScale(domain: 0...getYMax())
        .chartXAxis {
            AxisMarks {
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour())
            }
        }
        .foregroundColor(.accent)

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

        return Array(dataPoints[firstNonZeroIndex...lastNonZeroIndex])
    }
}

#Preview {
    SolarChart(
        maxProductionkW: .constant(11000),
        solarProduction: .constant(ConsumptionData.fake())
    )
}
