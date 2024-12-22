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
        let data = solarProduction.data.map {
            SolarDataPoint(
                time: $0.date,
                production: $0.productionWatts / 1000
            )
        }

        Chart {
            ForEach(data) { dataPoint in
                LineMark(
                    x: .value("Time", dataPoint.time),
                    y: .value("kW", dataPoint.production)
                )
                .interpolationMethod(.cardinal)

            }
        }
        //.chartYScale(domain: 0...maxProductionkW)
        .chartLegend()
        .chartYAxisLabel("kW")
        .chartYScale(domain: 0...getYMax())
        .chartXAxisLabel("Time", alignment: .leading)
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 1)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour())
            }
        }
        .foregroundColor(.accent)

    }

    private func getYMax() -> Double {
        let maxProduction =
            solarProduction.data.max(
                by: { $0.productionWatts > $1.productionWatts })?
            .productionWatts
            ?? 0

        return maxProduction <= 0
            ? maxProductionkW / 1000
            : maxProduction
    }
}

#Preview {
    SolarChart(
        maxProductionkW: .constant(11000),
        solarProduction: .constant(ConsumptionData.fake())
    )
}
