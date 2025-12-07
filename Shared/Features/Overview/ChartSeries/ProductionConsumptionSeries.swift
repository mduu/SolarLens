import SwiftUI
import Charts

struct ProductionConsumptionSeries: ChartContent {
    var data: [MainDataItem]
    var isAccent: Bool
    var useAlternativeColors: Bool

    var body: some ChartContent {
        ForEach(data) { dataPoint in

            // Production (Solar)
            if !isAccent {
                AreaMark(
                    x: .value("Time", dataPoint.date.convertToLocalTime()),
                    y: .value("kW", Double(dataPoint.productionWatts) / 1000),
                    stacking: .unstacked
                )
                .interpolationMethod(.cardinal)
                .foregroundStyle(
                    .linearGradient(
                        colors: [
                            SerieColors.productionColor(useAlternativeColors: useAlternativeColors).opacity(0.5),
                            SerieColors.productionColor(useAlternativeColors: useAlternativeColors).opacity(0.1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .foregroundStyle(by: .value("Series", "Production"))
                .lineStyle(
                    StrokeStyle(lineWidth: 0)
                )
            }

            LineMark(
                x: .value("Time", dataPoint.date.convertToLocalTime()),
                y: .value("kW", Double(dataPoint.productionWatts) / 1000)
            )
            .interpolationMethod(.cardinal)
            .lineStyle(
                StrokeStyle(lineWidth: 1)
            )
            .accessibilityLabel("Production")
            .foregroundStyle(by: .value("Series", "Production"))

            // -- Consumption --
            if !isAccent {
                AreaMark(
                    x: .value("Time", dataPoint.date.convertToLocalTime()),
                    y: .value("kW", Double(dataPoint.consumptionWatts) / 1000),
                    stacking: .unstacked
                )
                .interpolationMethod(.cardinal)
                .foregroundStyle(
                    .linearGradient(
                        colors: [
                            SerieColors.consumptionColor(useAlternativeColors: useAlternativeColors).opacity(0.5),
                            SerieColors.consumptionColor(useAlternativeColors: useAlternativeColors).opacity(0.1),
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
                y: .value("kW", Double(dataPoint.consumptionWatts) / 1000)
            )
            .interpolationMethod(.cardinal)
            .lineStyle(
                StrokeStyle(lineWidth: 1, dash: isAccent ? [2, 2] : [])
            )
            .accessibilityLabel("Consumption")
            .foregroundStyle(by: .value("Series", "Consumption"))

        }  // :foreach
    }
}

#Preview("On white") {
    HStack {
        Chart {
            ProductionConsumptionSeries(
                data: MainData.fake().data,
                isAccent: false,
                useAlternativeColors: false
            )
        }
        .chartYAxis {
            AxisMarks(preset: .automatic) { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
    }
    .background(.white)
}

#Preview("On black") {
    HStack {
        Chart {
            ProductionConsumptionSeries(
                data: MainData.fake().data,
                isAccent: false,
                useAlternativeColors: false
            )
        }
        .chartYAxis {
            AxisMarks(preset: .automatic) { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
    }
    .background(.black)
}

#Preview("Darker Colors") {
    HStack {
        Chart {
            ProductionConsumptionSeries(
                data: MainData.fake().data,
                isAccent: false,
                useAlternativeColors: true
            )
        }
        .chartYAxis {
            AxisMarks(preset: .automatic) { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
    }
    .background(.blue.gradient)
}
