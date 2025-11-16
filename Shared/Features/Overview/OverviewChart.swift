import Charts
import SwiftUI

struct OverviewChart: View {

    var consumption: MainData
    var batteries: [BatteryHistory] = []
    var isSmall: Bool = false
    var isAccent: Bool = false
    var showBatteryCharge: Bool = true
    var showBatteryDischange: Bool = true
    var showBatteryPercentage: Bool = true
    var useAlternativeColors: Bool = false

    var anyBatteryLevel: Bool {
        consumption.data.isEmpty == false && consumption.data.contains(where: { $0.batteryLevel != nil })
    }

    var body: some View {

        Chart {

            ProductionConsumptionSeries(
                data: consumption.data,
                isAccent: isAccent,
                useAlternativeColors: useAlternativeColors
            )

            if !batteries.isEmpty {
                BatterySeries(
                    batteries: batteries,
                    isAccent: isAccent,
                    showCharging: showBatteryCharge,
                    showDischarging: showBatteryDischange
                )
            }

            if showBatteryPercentage && anyBatteryLevel {
                BatteryLevelSeries(
                    data: consumption.data,
                    maxY: getYMax(),
                    isAccent: isAccent,
                    useAlternativeColors: useAlternativeColors
                )
            }

        }
        .chartYAxis {
            AxisMarks(preset: .automatic) { value in
                AxisGridLine()
                    #if os(tvOS)
                        .foregroundStyle(useAlternativeColors ? .white : .primary)
                    #endif

                AxisValueLabel()
                    #if os(tvOS)
                        .foregroundStyle(useAlternativeColors ? .white : .primary)
                    #endif
            }
        }
        .chartYAxisLabel(isSmall ? "" : "kW")
        #if os(tvOS)
            .foregroundStyle(useAlternativeColors ? .white : .primary)
        #endif

        .chartYScale(domain: 0...getYMax())
        .chartXAxis {
            AxisMarks { value in
                AxisGridLine()
                    #if os(tvOS)
                        .foregroundStyle(useAlternativeColors ? .white : .primary)
                    #endif

                AxisValueLabel(
                    format: .dateTime.hour(.twoDigits(amPM: .omitted)).minute(
                        .twoDigits
                    )
                )
                #if os(tvOS)
                    .foregroundStyle(useAlternativeColors ? .white : .primary)
                #endif
            }
        }
        .chartLegend(isSmall ? .hidden : .visible)
        .chartForegroundStyleScale(
            [
                "Production": SerieColors.productionColor(useAlternativeColors: useAlternativeColors),
                "Consumption": SerieColors.consumptionColor(useAlternativeColors: useAlternativeColors),
                (showBatteryDischange ? "Battery consumption" : ""): (showBatteryDischange ? .indigo : .clear),
                (showBatteryCharge ? "Battery charged" : ""): (showBatteryCharge ? .purple : .clear),
                (showBatteryPercentage ? "Battery" : ""):
                    (showBatteryPercentage
                    ? SerieColors.batteryLevelColor(useAlternativeColors: useAlternativeColors) : .clear),
            ]
        )
        .frame(maxHeight: .infinity)
    }

    private func getTimeFormatter() -> DateFormatter {
        let result = DateFormatter()
        result.setLocalizedDateFormatFromTemplate("HH:mm")
        return result
    }

    private func getYMax() -> Double {
        let maxkW: Double? = consumption.data
            .map { Double(max($0.productionWatts, $0.consumptionWatts)) / 1000 }
            .max()

        guard let maxkW else { return 2.0 }

        return maxkW <= 0.005
            ? 2.0
            : maxkW * 1.1
    }

}

#Preview("Normal") {
    OverviewChart(
        consumption: MainData.fake()
    )
}

#Preview("Small") {
    OverviewChart(
        consumption: MainData.fake(),
        batteries: BatteryHistory.fakeHistory(),
        isSmall: true
    )
    .frame(height: 80)
}

#Preview("Alternative Colors") {
    OverviewChart(
        consumption: MainData.fake(),
        batteries: BatteryHistory.fakeHistory(),
        isSmall: true,
        useAlternativeColors: true
    )
    .frame(height: 80)
}
