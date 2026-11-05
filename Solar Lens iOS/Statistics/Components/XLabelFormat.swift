import SwiftUI

/// How a statistics chart labels the buckets along its x axis.
enum XLabelFormat {
    case weekday
    case dayOfMonth
    case isoWeekNumber
    case month
    case monthNarrow
    /// Months inside a single calendar year, so the year needs no repeating.
    case monthInYear
    case year
}

extension XLabelFormat {

    /// How many buckets to skip between x-axis labels so they stay readable.
    func axisStride(visibleCount count: Int) -> Int {
        switch self {
        case .weekday:
            return 1
        case .dayOfMonth:
            if count <= 14 { return 2 }
            if count <= 60 { return 7 }
            // > ~120 days: switch to month-based stride
            return 30
        case .isoWeekNumber:
            if count <= 5 { return 1 }
            // > 5 weeks: stride by ~4 weeks (month-ish)
            return 4
        case .month, .monthNarrow, .monthInYear:
            return count > 9 ? 2 : 1
        case .year:
            return 1
        }
    }

    /// The label under one bucket.
    @ViewBuilder
    func axisLabel(for date: Date, visibleCount: Int) -> some View {
        switch self {
        case .weekday:
            Text(date, format: .dateTime.weekday(.abbreviated))
        case .dayOfMonth:
            if visibleCount > 120 {
                Text(date, format: .dateTime.month(.abbreviated))
            } else if visibleCount > 14 {
                Text(date, format: .dateTime.day(.twoDigits).month(.abbreviated))
            } else {
                Text(date, format: .dateTime.day())
            }
        case .isoWeekNumber:
            if visibleCount > 5 {
                Text(date, format: .dateTime.month(.abbreviated))
            } else {
                Text("W\(Calendar(identifier: .iso8601).component(.weekOfYear, from: date))")
            }
        case .month, .monthNarrow:
            let calendar = Calendar.current
            let year = calendar.component(.year, from: date) % 100
            let month = calendar.component(.month, from: date)
            Text("\(year)/\(month)")
        case .monthInYear:
            Text(date, format: .dateTime.month(.abbreviated))
        case .year:
            Text(date, format: .dateTime.year())
        }
    }
}
