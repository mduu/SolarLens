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

    /// Rounds a date down onto this page's bucket grid.
    func align(_ date: Date) -> Date {
        switch self {
        case .day, .week, .month:
            return calendar.startOfDay(for: date)
        case .year:
            let comps = calendar.dateComponents([.year, .month], from: date)
            return calendar.date(from: comps) ?? calendar.startOfDay(for: date)
        case .decade:
            let comps = calendar.dateComponents([.year], from: date)
            return calendar.date(from: comps) ?? calendar.startOfDay(for: date)
        }
    }

    /// Where the visible window ends when it starts at `start`.
    func end(of start: Date) -> Date {
        calendar.date(byAdding: span, to: start) ?? start
    }

    /// The window that ends "now" — what the chart shows before the user
    /// scrolls anywhere. Mirrors the ranges the screens used to fetch:
    /// today, the last 7 days, the last month, the last 12 months.
    var presentWindowStart: Date {
        let now = Date()
        switch self {
        case .day:
            return calendar.startOfDay(for: now)
        case .week:
            return calendar.date(
                byAdding: .day, value: -6, to: calendar.startOfDay(for: now)
            ) ?? now
        case .month:
            let start = calendar.date(
                byAdding: .month, value: -1, to: calendar.startOfDay(for: now)
            ) ?? now
            return calendar.date(byAdding: .day, value: 1, to: start) ?? start
        case .year:
            let thisMonth = align(now)
            return calendar.date(byAdding: .month, value: -11, to: thisMonth)
                ?? thisMonth
        case .decade:
            let thisYear = align(now)
            return calendar.date(byAdding: .year, value: -9, to: thisYear)
                ?? thisYear
        }
    }

    /// Human label for the window starting at `start`, shown between the
    /// ‹ › buttons.
    func label(for start: Date) -> String {
        let end = end(of: start)
        let lastDay = calendar.date(byAdding: .day, value: -1, to: end) ?? end

        switch self {
        case .day:
            if calendar.isDateInToday(start) { return String(localized: "Today") }
            if calendar.isDateInYesterday(start) {
                return String(localized: "Yesterday")
            }
            return start.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        case .week, .month:
            let from = start.formatted(.dateTime.day().month(.abbreviated))
            let to = lastDay.formatted(.dateTime.day().month(.abbreviated).year())
            return "\(from) – \(to)"
        case .year:
            let from = start.formatted(.dateTime.month(.abbreviated).year())
            let to = lastDay.formatted(.dateTime.month(.abbreviated).year())
            return "\(from) – \(to)"
        case .decade:
            let from = start.formatted(.dateTime.year())
            let to = lastDay.formatted(.dateTime.year())
            return "\(from) – \(to)"
        }
    }
}
