import Charts
import SwiftUI

struct OverviewChart: View {

    var consumption: ConsumptionData
    var batteries: [BatteryHistory] = []
    var isSmall: Bool = false
    var isAccent: Bool = false

    var body: some View {

        Chart {
            if !batteries.isEmpty {
                BatterySeries(batteries: batteries, isAccent: isAccent)
            }

            ProductionConsumptionSeries(
                data: consumption.data,
                isAccent: isAccent
            )
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
                        .twoDigits
                    )
                )
            }
        }
        .chartForegroundStyleScale([
            "Production": .yellow,
            "Consumption": Color.teal,
            "Battery Consumption": Color.purple,
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
        consumption: ConsumptionData.fake()
    )
}

#Preview("Small") {
    OverviewChart(
        consumption: ConsumptionData.fake(),
        batteries: BatteryHistory.fakeHistory(),
        isSmall: true
    )
    .frame(height: 80)
}
