import SwiftUI
import Charts

struct GridSeries: ChartContent {
    var data: [MainDataItem]
    var isAccent: Bool
    var gridImportLabel: String
    var gridExportLabel: String

    var body: some ChartContent {
        ForEach(data) { dataPoint in
            let importKW = dataPoint.importedOverTimeWhatthours * 12 / 1000
            let exportKW = dataPoint.exportedOverTimeWhatthours * 12 / 1000

            // Grid Import
            if !isAccent {
                AreaMark(
                    x: .value("Time", dataPoint.date.convertToLocalTime()),
                    y: .value("kW", importKW),
                    stacking: .unstacked
                )
                .interpolationMethod(.cardinal)
                .foregroundStyle(
                    .linearGradient(
                        colors: [
                            SerieColors.gridImportColor().opacity(0.4),
                            SerieColors.gridImportColor().opacity(0.05),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .foregroundStyle(by: .value("Series", gridImportLabel))
                .lineStyle(StrokeStyle(lineWidth: 0))
            }

            LineMark(
                x: .value("Time", dataPoint.date.convertToLocalTime()),
                y: .value("kW", importKW)
            )
            .interpolationMethod(.cardinal)
            .lineStyle(StrokeStyle(lineWidth: 1))
            .foregroundStyle(by: .value("Series", gridImportLabel))

            // Grid Export
            if !isAccent {
                AreaMark(
                    x: .value("Time", dataPoint.date.convertToLocalTime()),
                    y: .value("kW", exportKW),
                    stacking: .unstacked
                )
                .interpolationMethod(.cardinal)
                .foregroundStyle(
                    .linearGradient(
                        colors: [
                            SerieColors.gridExportColor().opacity(0.4),
                            SerieColors.gridExportColor().opacity(0.05),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .foregroundStyle(by: .value("Series", gridExportLabel))
                .lineStyle(StrokeStyle(lineWidth: 0))
            }

            LineMark(
                x: .value("Time", dataPoint.date.convertToLocalTime()),
                y: .value("kW", exportKW)
            )
            .interpolationMethod(.cardinal)
            .lineStyle(StrokeStyle(lineWidth: 1))
            .foregroundStyle(by: .value("Series", gridExportLabel))
        }
    }
}
