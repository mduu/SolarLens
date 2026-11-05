import SwiftUI

/// A grid of tiles, each tinted by a `MapMetric` for its slice of time: how
/// self-sufficient it was, or whether it ran a surplus or a deficit.
///
/// The same picture at every scale: a week as days × hours, a year as
/// months × days, the whole installation as years × months. What a bar chart
/// has to be read for — the cloudy stretch, the hours the grid steps in every
/// evening, the month that is weaker than it was last year — shows up here as
/// a pattern. A month has its own view, `AutarkyCalendarView`, because a month
/// is better read as a calendar.
struct EfficiencyHeatMap: View {

    enum Cell {
        /// Not a slice of time at all — the 30th of February.
        case absent
        /// A real slice without figures: still to come, or before the
        /// installation existed.
        case empty
        case filled(DayStatistic)
    }

    struct Row: Identifiable {
        let id: Int
        let label: String
        let cells: [Cell]
    }

    var rows: [Row]

    /// Labels under the grid, keyed by column index. Sparse on purpose —
    /// thirty-one day numbers would be a ruler, not a label.
    var columnLabels: [Int: String]

    var cellHeight: CGFloat = 12

    /// Writes the figure into each tile. Only for grids coarse enough to
    /// hold it.
    var showsValues = false

    @Binding var metric: MapMetric

    /// Lets a horizontal swipe page through time, as it does on the charts
    /// this view takes the place of.
    var scrollConfig: ChartTimeScrollConfig?

    private let labelWidth: CGFloat = 30
    private let gap: CGFloat = 2

    private var columnCount: Int { rows.map(\.cells.count).max() ?? 0 }

    /// The largest figure among the tiles, for metrics whose tint is relative
    /// to it.
    private var strongest: Double {
        metric.strongest(
            among: rows.lazy.flatMap(\.cells).compactMap { cell -> Double? in
                guard case .filled(let statistic) = cell else { return nil }
                return metric.value(of: statistic)
            }
        )
    }

    var body: some View {
        // Once per render, not once per tile.
        let strongest = strongest

        VStack(spacing: 10) {
            VStack(spacing: gap) {
                ForEach(rows) { row in
                    HStack(spacing: gap) {
                        Text(verbatim: row.label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .frame(width: labelWidth, alignment: .leading)

                        ForEach(Array(row.cells.enumerated()), id: \.offset) { _, cell in
                            tile(cell, strongest: strongest)
                        }
                    }
                }

                HStack(spacing: gap) {
                    Color.clear.frame(width: labelWidth, height: 12)
                    ForEach(0..<columnCount, id: \.self) { column in
                        Text(verbatim: columnLabels[column] ?? "")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                            .fixedSize()
                            .frame(maxWidth: .infinity, alignment: showsValues ? .center : .leading)
                    }
                }
            }
            .timePaging(scrollConfig)

            MapMetricPicker(metric: $metric)

            MapMetricCaption(metric: metric)
        }
    }

    @ViewBuilder
    private func tile(_ cell: Cell, strongest: Double) -> some View {
        switch cell {
        case .absent:
            Color.clear.frame(height: cellHeight)
        case .empty:
            shape.fill(Color.gray.opacity(0.07)).frame(height: cellHeight)
        case .filled(let statistic):
            if let value = metric.value(of: statistic) {
                shape
                    .fill(metric.fill(for: value, strongest: strongest))
                    .frame(height: cellHeight)
                    .overlay {
                        if showsValues {
                            Text(verbatim: metric.text(for: value))
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .monospacedDigit()
                                .minimumScaleFactor(0.6)
                                .lineLimit(1)
                                .padding(.horizontal, 1)
                        }
                    }
            } else {
                shape.fill(Color.gray.opacity(0.07)).frame(height: cellHeight)
            }
        }
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: showsValues ? 5 : 2.5)
    }
}

// MARK: - Layouts

extension EfficiencyHeatMap {

    /// A week as seven rows of twenty-four hours.
    static func weekByHour(_ hours: [DayStatistic], week: Range<Date>) -> [Row] {
        let calendar = Calendar.current
        var byHour: [Date: DayStatistic] = [:]
        for hour in hours {
            byHour[hour.day] = hour
        }

        return (0..<7).compactMap { offset in
            guard
                let day = calendar.date(byAdding: .day, value: offset, to: week.lowerBound)
            else { return nil }

            let cells: [Cell] = (0..<24).map { hour in
                guard
                    let start = calendar.date(
                        bySettingHour: hour, minute: 0, second: 0, of: day
                    )
                else { return .absent }
                return byHour[start].map(Cell.filled) ?? .empty
            }
            return Row(
                id: offset,
                label: day.formatted(.dateTime.weekday(.abbreviated)),
                cells: cells
            )
        }
    }

    /// Every sixth hour, written as a time of day — "06:00", "6:00 AM" —
    /// rather than as a bare number. A row of 0, 6, 12, 18 under a grid does
    /// not say what it counts.
    ///
    /// With the minutes on purpose: the hour alone formats as "6 Uhr" in
    /// German but as a bare "06" under an English 24-hour setting, which is
    /// the unlabelled number again.
    static var hourColumnLabels: [Int: String] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var labels: [Int: String] = [:]
        for hour in stride(from: 0, to: 24, by: 6) {
            guard let time = calendar.date(byAdding: .hour, value: hour, to: today)
            else { continue }
            labels[hour] = time.formatted(.dateTime.hour().minute())
        }
        return labels
    }

    /// A year as twelve rows of up to thirty-one days.
    static func yearByDay(_ days: [DayStatistic], year: Date) -> [Row] {
        let calendar = Calendar.current
        var byDay: [Date: DayStatistic] = [:]
        for day in days {
            byDay[calendar.startOfDay(for: day.day)] = day
        }
        let yearNumber = calendar.component(.year, from: year)

        return (1...12).compactMap { month in
            guard
                let first = calendar.date(
                    from: DateComponents(year: yearNumber, month: month, day: 1)
                ),
                let length = calendar.range(of: .day, in: .month, for: first)?.count
            else { return nil }

            let cells: [Cell] = (0..<31).map { offset in
                guard offset < length,
                    let day = calendar.date(byAdding: .day, value: offset, to: first)
                else { return .absent }
                return byDay[day].map(Cell.filled) ?? .empty
            }
            return Row(
                id: month,
                label: first.formatted(.dateTime.month(.abbreviated)),
                cells: cells
            )
        }
    }

    static let dayColumnLabels: [Int: String] = [0: "1", 9: "10", 19: "20", 30: "31"]

    /// Every year on record as a row of twelve months.
    static func yearsByMonth(_ days: [DayStatistic]) -> [Row] {
        let calendar = Calendar.current

        // Keyed by plain numbers. `DateComponents` looks like the natural key
        // and is not: the ones a calendar hands out carry `isLeapMonth`, the
        // ones built by hand do not, and although the two compare equal they
        // hash differently — so the lookup below would mostly miss.
        var byMonth: [Int: [Int: DayStatistic]] = [:]
        for day in days {
            let year = calendar.component(.year, from: day.day)
            let month = calendar.component(.month, from: day.day)
            byMonth[year, default: [:]][month] =
                byMonth[year]?[month].map { $0.adding(day) } ?? day
        }

        return byMonth.keys.sorted().map { year in
            Row(
                id: year,
                label: String(year),
                cells: (1...12).map { month in
                    byMonth[year]?[month].map(Cell.filled) ?? .empty
                }
            )
        }
    }

    static var monthColumnLabels: [Int: String] {
        Dictionary(
            uniqueKeysWithValues: Calendar.current.veryShortStandaloneMonthSymbols
                .enumerated().map { ($0.offset, $0.element) }
        )
    }
}

#if DEBUG
    #Preview("Year by day") {
        @Previewable @State var metric = MapMetric.autarky
        let days = (1...12).flatMap { DayStatistic.previewMonth(month: $0) }

        EfficiencyHeatMap(
            rows: EfficiencyHeatMap.yearByDay(days, year: days[0].day),
            columnLabels: EfficiencyHeatMap.dayColumnLabels,
            metric: $metric
        )
        .padding(.horizontal)
    }

    #Preview("Years by month") {
        @Previewable @State var metric = MapMetric.autarky
        let days = (1...12).flatMap { DayStatistic.previewMonth(month: $0) }

        EfficiencyHeatMap(
            rows: EfficiencyHeatMap.yearsByMonth(days),
            columnLabels: EfficiencyHeatMap.monthColumnLabels,
            cellHeight: 24,
            showsValues: true,
            metric: $metric
        )
        .padding(.horizontal)
    }
#endif
