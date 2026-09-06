import SwiftUI

/// One "page" of a scrollable chart: the span the user sees at once, the step
/// the ‹ › buttons move by, and the grid the scroll settles on.
///
/// iOS only — the watch and TV charts always show a single fixed window.
enum ChartPage {
    /// 24 hours of 5-minute samples.
    case day
    /// Seven days of daily buckets.
    case week
    /// One calendar month of daily buckets.
    case month
    /// Twelve months of monthly buckets.
    case year
    /// Ten years of yearly buckets.
    case decade

    private var calendar: Calendar { Calendar.current }

    /// Monday-based weeks, whatever the device locale calls its first day.
    /// `BucketStatisticsStore.weekBuckets` groups with the same calendar, so a
    /// week window and the bucket sitting in it can never disagree.
    private var isoCalendar: Calendar { Calendar(identifier: .iso8601) }

    /// How far one ‹ / › tap moves.
    var step: DateComponents {
        switch self {
        case .day: DateComponents(day: 1)
        case .week: DateComponents(day: 7)
        case .month: DateComponents(month: 1)
        case .year: DateComponents(year: 1)
        case .decade: DateComponents(year: 10)
        }
    }

    /// The span of one visible window, as calendar components.
    var span: DateComponents {
        switch self {
        case .day: DateComponents(day: 1)
        case .week: DateComponents(day: 7)
        case .month: DateComponents(month: 1)
        case .year: DateComponents(year: 1)
        case .decade: DateComponents(year: 10)
        }
    }

    /// How many pages back the user may go before the ‹ button stops. Generous
    /// enough to browse a season, bounded so a stuck finger cannot walk the
    /// chart into years that never had an installation.
    var maximumScrollbackPages: Int {
        switch self {
        case .day: 92
        case .week: 52
        case .month: 36
        case .year: 10
        case .decade: 3
        }
    }

    /// Rounds a date down onto this page's bucket grid — the first instant of
    /// the calendar period holding it.
    ///
    /// Going through date components rather than arithmetic keeps this right
    /// across a daylight-saving change: `date(from:)` resolves to the real
    /// first instant of the day, not to "midnight minus an hour".
    func align(_ date: Date) -> Date {
        switch self {
        case .day:
            return calendar.startOfDay(for: date)
        case .week:
            let comps = isoCalendar.dateComponents(
                [.yearForWeekOfYear, .weekOfYear], from: date
            )
            return isoCalendar.date(from: comps) ?? calendar.startOfDay(for: date)
        case .month:
            let comps = calendar.dateComponents([.year, .month], from: date)
            return calendar.date(from: comps) ?? calendar.startOfDay(for: date)
        case .year, .decade:
            let comps = calendar.dateComponents([.year], from: date)
            return calendar.date(from: comps) ?? calendar.startOfDay(for: date)
        }
    }

    /// Pages whose newest window stops at the end of the bucket holding today
    /// instead of running out to its nominal span.
    ///
    /// Only `.decade` does. Its ten-year span is a container for year buckets,
    /// so an installation registered in 2022 would otherwise draw four real
    /// bars squeezed against six empty years that have not happened yet.
    var trimsFutureBuckets: Bool {
        self == .decade
    }

    /// Start of the bucket following the one that holds `date` — where a
    /// trimmed window ends.
    func endOfCurrentBucket(containing date: Date) -> Date {
        switch self {
        case .decade:
            let comps = calendar.dateComponents([.year], from: date)
            let start = calendar.date(from: comps) ?? calendar.startOfDay(for: date)
            return calendar.date(byAdding: .year, value: 1, to: start) ?? start
        default:
            return end(of: align(date))
        }
    }

    /// Where the visible window ends when it starts at `start`.
    func end(of start: Date) -> Date {
        calendar.date(byAdding: span, to: start) ?? start
    }

    /// The newest window — what the chart shows before the user scrolls
    /// anywhere: simply the calendar period that holds today.
    ///
    /// Part of that period has usually not happened yet. The current month
    /// runs to the 1st of the next one and the chart shades the remainder,
    /// exactly as the day page has always done for the hours after "now".
    var presentWindowStart: Date {
        let now = Date()
        switch self {
        case .day, .week, .month, .year:
            return align(now)
        case .decade:
            // Deliberately still rolling. An aligned decade would run up to
            // nine years into the future, which is a very empty chart.
            let thisYear = align(now)
            return calendar.date(byAdding: .year, value: -9, to: thisYear)
                ?? thisYear
        }
    }

    /// Human label for the window starting at `start`, shown between the
    /// ‹ › buttons.
    ///
    /// `windowEnd` lets a trimmed page label what it actually shows rather
    /// than its nominal span — an "Overall" window cut back to the running
    /// year would otherwise announce years it does not draw.
    func label(for start: Date, to windowEnd: Date? = nil) -> String {
        let end = windowEnd ?? end(of: start)
        let lastDay = calendar.date(byAdding: .day, value: -1, to: end) ?? end

        switch self {
        case .day:
            if calendar.isDateInToday(start) { return String(localized: "Today") }
            if calendar.isDateInYesterday(start) {
                return String(localized: "Yesterday")
            }
            return start.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        case .week:
            // One interval rather than two dates joined by a hard-coded dash,
            // so the shared month and year collapse the way each language
            // expects. `lastDay` because `end` is the exclusive next Monday.
            return (start..<lastDay).formatted(
                .interval.day().month(.abbreviated).year()
            )
        case .month:
            return start.formatted(.dateTime.month(.wide).year())
        case .year:
            return start.formatted(.dateTime.year())
        case .decade:
            let from = start.formatted(.dateTime.year())
            let to = lastDay.formatted(.dateTime.year())
            // A window trimmed back to a single year should say so plainly.
            return from == to ? from : "\(from) – \(to)"
        }
    }
}
