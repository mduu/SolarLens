import Charts
import SwiftUI

/// What each bucket left over: production minus consumption, one bar per
/// bucket, rising from the baseline for a surplus and hanging below it for a
/// deficit.
///
/// The four-series bars show a bucket's two totals and leave the subtraction
/// to the reader. This draws the result — which day, month or year ran ahead
/// and which fell behind, and by how much — and writes the period's own
/// balance out as a figure underneath.
struct EnergyBalanceChart: View {
    /// The buckets inside the visible window.
    var data: [DayStatistic]
    var xUnit: Calendar.Component
    var xLabelFormat: XLabelFormat

    var chartHeight: CGFloat = 200
    var scrollConfig: ChartTimeScrollConfig?

    /// How many buckets the window is meant to hold, including the ones that
    /// have not happened yet — keeps the axis labels steady while the current
    /// period fills up.
    var visibleUnitCount: Int?
    var futureShading: ChartFutureShading?

    // Yellow where the roof made more than the house used, teal where it was
    // the other way round — the colours the intraday chart draws production
    // and consumption in.
    private let surplusColor = SerieColors.productionColor(useAlternativeColors: false)
    private let deficitColor = SerieColors.consumptionColor(useAlternativeColors: false)

    private var visibleCount: Int { visibleUnitCount ?? data.count }

    private func balance(of bucket: DayStatistic) -> Double {
        bucket.production - bucket.consumption
    }

    /// The period's own balance, in watt-hours.
    private var total: Double {
        data.reduce(0) { $0 + balance(of: $1) }
    }

    private var useMWh: Bool {
        let peak = data.map { abs(balance(of: $0)) }.max() ?? 0
        return max(peak, abs(total)) >= 1_000_000
    }

    private var divisor: Double { useMWh ? 1_000_000 : 1000 }

    /// "+0.5 MWh", "−12.3 kWh", "0" — with a real minus sign.
    private func signed(_ wattHours: Double) -> String {
        let figure = abs(wattHours).formatWattHours(asMWh: useMWh, withUnit: true)
        guard abs(wattHours) >= (useMWh ? 50_000 : 50) else { return "0" }
        return (wattHours > 0 ? "+" : "−") + figure
    }

    var body: some View {
        VStack(spacing: 8) {
            // A window that still has time to run is not empty, it has only
            // just begun — on the 1st of a month it holds no buckets yet.
            if data.isEmpty && futureShading == nil {
                ContentUnavailableView(
                    "No Data Available",
                    systemImage: "chart.bar.xaxis",
                    description: Text("Statistics will appear here when data is available.")
                )
                .frame(height: 250)
            } else {
                chart
            }

            HStack(alignment: .firstTextBaseline) {
                Text("Production minus consumption")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 8)
                if !data.isEmpty {
                    Text(verbatim: signed(total))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }
            }
        }
    }

    private var chart: some View {
        let values = data.map { balance(of: $0) / divisor }
        let highest = max(values.max() ?? 0, 0)
        let lowest = min(values.min() ?? 0, 0)
        // A little air beyond the tallest bar either way, and never a
        // zero-height domain.
        let padding = max((highest - lowest) * 0.1, 0.05)

        return Chart {
            ForEach(data, id: \.day) { item in
                let value = balance(of: item) / divisor

                BarMark(
                    x: .value("Period", item.day, unit: xUnit),
                    y: .value("Balance", value),
                    width: .ratio(0.68)
                )
                .cornerRadius(3)
                .foregroundStyle(fill(surplus: value >= 0))
            }

            RuleMark(y: .value("Balance", 0))
                .lineStyle(StrokeStyle(lineWidth: 0.75))
                .foregroundStyle(Color.secondary)
        }
        .chartYScale(domain: (lowest - padding)...(highest + padding))
        .chartTimeScroll(scrollConfig)
        .chartFutureShading(futureShading)
        .chartXAxis {
            AxisMarks(
                values: .stride(
                    by: xUnit, count: xLabelFormat.axisStride(visibleCount: visibleCount)
                )
            ) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        xLabelFormat.axisLabel(for: date, visibleCount: visibleCount)
                    }
                }
                AxisGridLine()
                AxisTick()
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let energy = value.as(Double.self) {
                        Text(verbatim: signed(energy * divisor))
                    }
                }
            }
        }
        .chartLegend(.hidden)
        .frame(height: chartHeight)
    }

    /// Strongest at the bar's free end, fading towards the baseline it grows
    /// from — in either direction.
    private func fill(surplus: Bool) -> LinearGradient {
        surplus
            ? LinearGradient(
                colors: [surplusColor.opacity(0.95), surplusColor.opacity(0.55)],
                startPoint: .top,
                endPoint: .bottom
            )
            : LinearGradient(
                colors: [deficitColor.opacity(0.5), deficitColor.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
    }
}

#if DEBUG
    #Preview("Year") {
        EnergyBalanceChart(
            data: DayStatistic.previewYear(),
            xUnit: .month,
            xLabelFormat: .monthInYear
        )
        .padding(.horizontal)
    }

    #Preview("Month, autumn") {
        EnergyBalanceChart(
            data: DayStatistic.previewMonth(month: 9),
            xUnit: .day,
            xLabelFormat: .dayOfMonth
        )
        .padding(.horizontal)
    }

    #Preview("Week") {
        EnergyBalanceChart(
            data: Array(DayStatistic.previewMonth(month: 6).prefix(7)),
            xUnit: .day,
            xLabelFormat: .weekday
        )
        .padding(.horizontal)
    }
#endif
