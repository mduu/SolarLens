import SwiftUI
import Charts

struct ProductionConsumptionSeries: ChartContent {
    var data: [ConsumptionItem]
    var isAccent: Bool

    var body: some ChartContent {
        ForEach(data) { dataPoint in

            // Production (Solar)
            if !isAccent {
                AreaMark(
                    x: .value("Time", dataPoint.date.convertToLocalTime()),
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
                x: .value("Time", dataPoint.date.convertToLocalTime()),
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
                    x: .value("Time", dataPoint.date.convertToLocalTime()),
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
                x: .value("Time", dataPoint.date.convertToLocalTime()),
                y: .value("kW", dataPoint.consumptionWatts / 1000)
            )
            .foregroundStyle(by: .value("Series", "Consumption"))
            .interpolationMethod(.cardinal)
            .lineStyle(
                StrokeStyle(lineWidth: 1, dash: isAccent ? [2, 2] : [])
            )

        }  // :foreach
    }
}

#Preview {
    HStack {
        Chart {
            ProductionConsumptionSeries(
                data: ConsumptionData.fake().data,
                isAccent: false
            )
        }
        .chartYAxis {
            AxisMarks(preset: .automatic) { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
    }
}
