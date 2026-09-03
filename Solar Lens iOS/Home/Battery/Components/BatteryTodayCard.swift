import Charts
import SwiftUI

struct BatteryTodayCard: View {
    /// Everything loaded so far — the marks come from here so the chart has
    /// something to show on both sides of the visible window while scrolling.
    let mainData: MainData?
    let batteryHistory: [BatteryHistory]?

    /// The window on screen. Totals and the y axis describe this, not the
    /// whole loaded range.
    var window: Range<Date>?
    var windowLabel: String = String(localized: "Today")
    var scrollConfig: ChartTimeScrollConfig?
    var isLoading: Bool = false

    /// The part of the visible window that is still ahead, shaded so today's
    /// empty evening does not read as missing data.
    var futureShading: ChartFutureShading?

    // `window` is in real time, the sample dates are not — see `ChartPlotSpace`.
    private var visibleSamples: [MainDataItem] {
        let all = mainData?.data ?? []
        guard let window else { return all }
        return all.filter { window.contains(ChartPlotSpace.fromApi($0.date)) }
    }

    private var visibleBatteryItems: [BatteryHistoryItem] {
        let all = (batteryHistory ?? []).flatMap { $0.items }
        guard let window else { return all }
        return all.filter { window.contains(ChartPlotSpace.fromApi($0.date)) }
    }

    var body: some View {
        let totalCharged = visibleSamples.reduce(0.0) { $0 + $1.batteryChargedWh }
        let totalDischarged = visibleSamples.reduce(0.0) { $0 + $1.batteryDischargedWh }

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.7))
                Text(windowLabel)
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.7))
            }

            // Totals
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.caption)
                        .foregroundStyle(.purple)
                    Text("Charged:")
                        .font(.caption)
                        .foregroundStyle(.primary.opacity(0.7))
                    Text(totalCharged.formatWattHoursAsKiloWattsHours(widthUnit: true))
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.caption)
                        .foregroundStyle(.indigo)
                    Text("Discharged:")
                        .font(.caption)
                        .foregroundStyle(.primary.opacity(0.7))
                    Text(totalDischarged.formatWattHoursAsKiloWattsHours(widthUnit: true))
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                Spacer()
            }

            // Chart
            if let mainData, let batteryHistory, !batteryHistory.isEmpty {
                let maxkW =
                    visibleBatteryItems
                    .map { max($0.averagePowerChargedW, $0.averagePowerDischargedW) / 1000 }
                    .max() ?? 2.0
                let yMax = max(maxkW * 1.1, 0.5)

                Chart {
                    BatterySeries(
                        batteries: batteryHistory,
                        isAccent: false,
                        batteryConsumptionLabel: String(localized: "Discharged"),
                        batteryChargedLabel: String(localized: "Charged")
                    )

                    if mainData.data.contains(where: { $0.batteryLevel != nil }) {
                        BatteryLevelSeries(
                            data: mainData.data,
                            maxY: yMax,
                            isAccent: false,
                            batteryLabel: String(localized: "Level")
                        )
                    }
                }
                .chartYScale(domain: 0...yMax)
                .chartFutureShading(futureShading)
                .chartTimeScroll(scrollConfig)
                .chartYAxis {
                    AxisMarks(preset: .automatic) { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .chartYAxisLabel("kW")
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisValueLabel(
                            format: .dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)
                        )
                    }
                }
                .chartLegend(.visible)
                .chartLegend(spacing: 4)
                .chartForegroundStyleScale([
                    String(localized: "Discharged"): Color.indigo,
                    String(localized: "Charged"): Color.purple,
                    String(localized: "Level"): SerieColors.batteryLevelColor(useAlternativeColors: false),
                ])
                .frame(height: 180)
            } else if mainData == nil || isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}
