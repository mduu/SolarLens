import Charts
import SwiftUI

struct BatterySeries: ChartContent {
    var batteries: [BatteryHistory] = []
    var isAccent: Bool

    var body: some ChartContent {
        let historyItems = flattenallBatteryItems()
        ForEach(historyItems) { batteryItem in

            // Battery Consumption
            if !isAccent {
                AreaMark(
                    x: .value(
                        "Time",
                        batteryItem.date.convertToLocalTime()
                    ),
                    y: .value(
                        "kW",
                        batteryItem.averagePowerDischargedW / 1000
                    ),
                    stacking: .unstacked
                )
                .interpolationMethod(.cardinal)
                .foregroundStyle(
                    .linearGradient(
                        colors: [
                            .purple.opacity(0.5),
                            .purple.opacity(0.1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .lineStyle(
                    StrokeStyle(lineWidth: 0)
                )
                .foregroundStyle(
                    by: .value("Series", "Battery consumption")
                )
            }

            LineMark(
                x: .value(
                    "Time",
                    batteryItem.date.convertToLocalTime()
                ),
                y: .value(
                    "kW",
                    batteryItem.averagePowerDischargedW / 1000
                )
            )
            .foregroundStyle(by: .value("Series", "Battery consumption"))
            .interpolationMethod(.cardinal)
            .lineStyle(
                StrokeStyle(lineWidth: 1, dash: isAccent ? [2, 2] : [])
            )
            
            // Battery Charging
            if !isAccent {
                AreaMark(
                    x: .value(
                        "Time",
                        batteryItem.date.convertToLocalTime()
                    ),
                    y: .value(
                        "kW",
                        batteryItem.averagePowerChargedW / 1000
                    ),
                    stacking: .unstacked
                )
                .interpolationMethod(.cardinal)
                .foregroundStyle(
                    .linearGradient(
                        colors: [
                            .pink.opacity(0.5),
                            .pink.opacity(0.1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .lineStyle(
                    StrokeStyle(lineWidth: 0)
                )
                .foregroundStyle(
                    by: .value("Series", "Battery charged")
                )
            }

            LineMark(
                x: .value(
                    "Time",
                    batteryItem.date.convertToLocalTime()
                ),
                y: .value(
                    "kW",
                    batteryItem.averagePowerChargedW / 1000
                )
            )
            .foregroundStyle(by: .value("Series", "Battery charged"))
            .interpolationMethod(.cardinal)
            .lineStyle(
                StrokeStyle(lineWidth: 1, dash: isAccent ? [2, 2] : [])
            )
        }
    }

    private func flattenallBatteryItems() -> [BatteryHistoryItem] {
        batteries.flatMap { $0.items }
    }
}

#Preview {
    HStack {
        Chart {
            BatterySeries(
                batteries: BatteryHistory.fakeHistory(),
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
