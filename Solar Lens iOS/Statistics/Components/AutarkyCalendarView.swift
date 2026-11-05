import SwiftUI

/// A month as a calendar, each day tinted by one of the two efficiency
/// figures: how much of its consumption the house covered itself (autarky),
/// or how much of its production it kept (self-consumption).
///
/// The month-sized member of the `EfficiencyHeatMap` family. The percentage
/// is written in every tile, so the tint is never the only carrier of the
/// value, and a tap on a day shows the energy behind it.
struct AutarkyCalendarView: View {

    /// Day buckets; days outside `month` are ignored.
    var data: [DayStatistic]
    /// Any instant inside the month to draw.
    var month: Date
    /// Lets a horizontal swipe page to the neighbouring month, as it does on
    /// the charts this view takes the place of.
    var scrollConfig: ChartTimeScrollConfig?

    @Binding var metric: EfficiencyMetric
    @State private var selectedDay: Date?

    /// Monday-based, like the week page and the week buckets.
    private let calendar = Calendar(identifier: .iso8601)

    init(
        data: [DayStatistic], month: Date,
        metric: Binding<EfficiencyMetric>,
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

            EfficiencyMetricPicker(metric: $metric)

            Group {
                if let selectedDay, let statistic = byDay[selectedDay] {
                    detailRow(selectedDay, statistic)
                } else {
                    Text(metric.explanation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(height: 30)
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
                        Text(verbatim: "\(Int(value.rounded()))")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                        Text(verbatim: "%")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(.secondary)
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
            Text(verbatim: value.map { "\(Int($0.rounded()))%" } ?? "–")
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
        let strength = metric.tintStrength(for: value)
        return LinearGradient(
            colors: [metric.color.opacity(strength), metric.color.opacity(strength * 0.6)],
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
        @Previewable @State var metric = EfficiencyMetric.autarky

        AutarkyCalendarView(
            data: DayStatistic.previewMonth(month: 6),
            month: previewDate(month: 6),
            metric: $metric
        )
        .padding(.horizontal)
    }

    #Preview("Winter month, day selected") {
        @Previewable @State var metric = EfficiencyMetric.autarky

        AutarkyCalendarView(
            data: DayStatistic.previewMonth(month: 1),
            month: previewDate(month: 1),
            metric: $metric,
            selectedDay: previewDate(month: 1, day: 14)
        )
        .padding(.horizontal)
    }

    #Preview("Month in progress") {
        @Previewable @State var metric = EfficiencyMetric.selfConsumption

        AutarkyCalendarView(
            data: Array(DayStatistic.previewMonth(month: 10).prefix(11)),
            month: previewDate(month: 10),
            metric: $metric
        )
        .padding(.horizontal)
    }
#endif
