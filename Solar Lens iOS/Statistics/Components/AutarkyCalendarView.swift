import SwiftUI

/// A month as a calendar, each day tinted by a `MapMetric`: how much of its
/// consumption the house covered itself, how much of its production it kept,
/// or whether it made more than it used.
///
/// The month-sized member of the `EfficiencyHeatMap` family. The figure is
/// written in every tile, so the tint is never the only carrier of the value,
/// and a tap on a day shows the energy behind it.
struct AutarkyCalendarView: View {

    /// Day buckets; days outside `month` are ignored.
    var data: [DayStatistic]
    /// Any instant inside the month to draw.
    var month: Date
    /// Lets a horizontal swipe page to the neighbouring month, as it does on
    /// the charts this view takes the place of.
    var scrollConfig: ChartTimeScrollConfig?

    @Binding var metric: MapMetric
    @State private var selectedDay: Date?

    /// Monday-based, like the week page and the week buckets.
    private let calendar = Calendar(identifier: .iso8601)

    init(
        data: [DayStatistic], month: Date,
        metric: Binding<MapMetric>,
        scrollConfig: ChartTimeScrollConfig? = nil,
        selectedDay: Date? = nil
    ) {
        self.data = data
        self.month = month
        self.scrollConfig = scrollConfig
        _metric = metric
        _selectedDay = State(initialValue: selectedDay)
    }

    private var monthStart: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
    }

    private var days: [Date] {
        let count = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 30
        return (0..<count).compactMap {
            calendar.date(byAdding: .day, value: $0, to: monthStart)
        }
    }

    /// Empty cells before the 1st, so it lands under its weekday.
    private var leadingBlanks: Int {
        (calendar.component(.weekday, from: monthStart) + 5) % 7
    }

    private var byDay: [Date: DayStatistic] {
        Dictionary(
            data.map { (calendar.startOfDay(for: $0.day), $0) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    private var weekdaySymbols: [String] {
        let symbols = Calendar.current.veryShortStandaloneWeekdaySymbols
        return Array(symbols[1...] + symbols[..<1])
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 5), count: 7)

    /// The largest figure among the month's days, for metrics whose tint is
    /// relative to it.
    private var strongest: Double {
        metric.strongest(among: data.compactMap(metric.value(of:)))
    }

    var body: some View {
        VStack(spacing: 10) {
            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(verbatim: symbol)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }

                ForEach(0..<leadingBlanks, id: \.self) { _ in
                    Color.clear
                }

                ForEach(days, id: \.self) { day in
                    dayTile(day, statistic: byDay[day])
                }
            }
            .timePaging(scrollConfig)

            MapMetricPicker(metric: $metric)

            Group {
                if let selectedDay, let statistic = byDay[selectedDay] {
                    detailRow(selectedDay, statistic)
                } else {
                    MapMetricCaption(metric: metric)
                }
            }
            .frame(minHeight: 30)
        }
    }

    // MARK: - Tile

    private func dayTile(_ day: Date, statistic: DayStatistic?) -> some View {
        let value = statistic.flatMap(metric.value(of:))
        let isSelected = selectedDay == day

        return Button {
            selectedDay = isSelected ? nil : day
        } label: {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 9)
                    .fill(fill(for: value))

                Text(verbatim: "\(calendar.component(.day, from: day))")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                    .padding(.leading, 5)

                if let value {
                    HStack(alignment: .firstTextBaseline, spacing: 0.5) {
                        Text(verbatim: metric.text(for: value))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                        if let unit = metric.unitSuffix {
                            Text(verbatim: unit)
                                .font(.system(size: 8, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 8)
                }
            }
            .frame(height: 42)
            .overlay {
                if isSelected || calendar.isDateInToday(day) {
                    RoundedRectangle(cornerRadius: 9)
                        .strokeBorder(.primary.opacity(isSelected ? 0.8 : 0.35), lineWidth: 1.5)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(statistic == nil)
        .accessibilityLabel(
            Text(day, format: .dateTime.day().month(.wide))
        )
        .accessibilityValue(
            Text(verbatim: value.map { metric.text(for: $0) + (metric.unitSuffix ?? " kWh") } ?? "–")
        )
    }

    /// Kept translucent, like the fills of the intraday chart, so the labels
    /// can stay in the primary colour in both appearances. A day without
    /// figures — still to come, or before the installation — stays a faint
    /// placeholder so the month keeps its shape.
    private func fill(for value: Double?) -> LinearGradient {
        guard let value else {
            return LinearGradient(
                colors: [Color.gray.opacity(0.07)], startPoint: .top, endPoint: .bottom
            )
        }
        let tint = metric.fill(for: value, strongest: strongest)
        return LinearGradient(
            colors: [tint, tint.opacity(0.6)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Below the grid

    private func detailRow(_ day: Date, _ statistic: DayStatistic) -> some View {
        HStack(spacing: 12) {
            Text(day, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated))
                .fontWeight(.semibold)
            Spacer()
            detailValue(statistic.production, SerieColors.productionColor(useAlternativeColors: false))
            detailValue(statistic.consumption, SerieColors.consumptionColor(useAlternativeColors: false))
            detailValue(statistic.imported, StatisticsSeries.imported.color)
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .frame(maxHeight: .infinity)
        .background(Color.gray.opacity(0.12), in: Capsule())
    }

    private func detailValue(_ wattHours: Double, _ color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(verbatim: wattHours.formatWattHoursAdaptive(withUnit: true))
                .monospacedDigit()
        }
    }
}

#if DEBUG
    private func previewDate(month: Int, day: Int = 1) -> Date {
        Calendar(identifier: .iso8601)
            .date(from: DateComponents(year: 2026, month: month, day: day)) ?? Date()
    }

    #Preview("Summer month") {
        @Previewable @State var metric = MapMetric.autarky

        AutarkyCalendarView(
            data: DayStatistic.previewMonth(month: 6),
            month: previewDate(month: 6),
            metric: $metric
        )
        .padding(.horizontal)
    }

    #Preview("Winter month, day selected") {
        @Previewable @State var metric = MapMetric.autarky

        AutarkyCalendarView(
            data: DayStatistic.previewMonth(month: 1),
            month: previewDate(month: 1),
            metric: $metric,
            selectedDay: previewDate(month: 1, day: 14)
        )
        .padding(.horizontal)
    }

    #Preview("Month in progress") {
        @Previewable @State var metric = MapMetric.selfConsumption

        AutarkyCalendarView(
            data: Array(DayStatistic.previewMonth(month: 10).prefix(11)),
            month: previewDate(month: 10),
            metric: $metric
        )
        .padding(.horizontal)
    }
#endif
