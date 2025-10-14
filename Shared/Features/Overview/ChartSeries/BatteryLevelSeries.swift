import Charts
import SwiftUI

struct BatteryLevelSeries: ChartContent {
    var data: [MainDataItem]
    var maxY: Double
    var isAccent: Bool
    var useAlternativeColors: Bool

    func getValue(_ percent: Int?) -> Double {
        let doubleValue = percent != nil ? Double(percent!) : 0.0
        let value: Double = maxY / 100 * doubleValue
        return value
    }

    var body: some ChartContent {

        ForEach(data) { dataPoint in

            LineMark(
                x: .value("Time", dataPoint.date.convertToLocalTime()),
                y: .value("%", getValue(dataPoint.batteryLevel))
            )
            .interpolationMethod(.cardinal)
            .lineStyle(
                StrokeStyle(lineWidth: 1, dash: isAccent ? [4, 3] : [4, 3])
            )
            .accessibilityLabel("Battery")
            .foregroundStyle(by: .value("Series", "Battery"))

        }

    }
}

#Preview("On white") {
    HStack {
        Chart {
            BatteryLevelSeries(
                data: MainData.fake().data,
                maxY: 5.3,
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
        .chartForegroundStyleScale(
            [
                "Battery": SerieColors.batteryLevelColor(useDarkerColors: false)
            ]
        )
    }
    .background(.white)
}

#Preview("On black") {
    HStack {
        Chart {
            BatteryLevelSeries(
                data: MainData.fake().data,
                maxY: 5.3,
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
        .chartForegroundStyleScale(
            [
                "Battery": SerieColors.batteryLevelColor(useDarkerColors: false)
            ]
        )
    }
    .background(.black)
}
