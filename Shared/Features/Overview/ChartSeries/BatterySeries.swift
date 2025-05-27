import Charts
import SwiftUI

struct BatterySeries: ChartContent {
    var batteries: [BatteryHistory] = []
    var isAccent: Bool
    var showCharging: Bool = true
    var showDischarging: Bool = true

    var body: some ChartContent {
        let historyItems = flattenallBatteryItems()
        ForEach(historyItems) { batteryItem in

            if showDischarging {

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
                    .interpolationMethod(.linear)
                    .foregroundStyle(
                        .linearGradient(
                            colors: [
                                .indigo.opacity(0.25),
                                .indigo.opacity(0.05),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .lineStyle(
                        StrokeStyle(lineWidth: 0)
                    )
                    .foregroundStyle(by: .value("Series", "Battery consumption"))
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
                .interpolationMethod(.linear)
                .lineStyle(
                    StrokeStyle(lineWidth: 1, dash: isAccent ? [2, 2] : [])
                )
                .foregroundStyle(by: .value("Series", "Battery consumption"))
                .accessibilityLabel("Battery consumption")
            }

            if showCharging {
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
                    .interpolationMethod(.linear)
                    .foregroundStyle(
                        .linearGradient(
                            colors: [
                                .purple.opacity(0.25),
                                .purple.opacity(0.05),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .lineStyle(
                        StrokeStyle(lineWidth: 0)
                    )
                    .foregroundStyle(by: .value("Series", "Battery charged"))
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
                .interpolationMethod(.linear)
                .lineStyle(
                    StrokeStyle(lineWidth: 1, dash: isAccent ? [2, 2] : [])
                )
                .accessibilityLabel("Battery charged")
                .foregroundStyle(by: .value("Series", "Battery charged"))
            }
        }
    }

    private func flattenallBatteryItems() -> [BatteryHistoryItem] {
        batteries
            .flatMap { $0.items }
            .filter {
                !$0.averagePowerChargedW.isZero
                    || !$0.averagePowerDischargedW.isZero
            }
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
