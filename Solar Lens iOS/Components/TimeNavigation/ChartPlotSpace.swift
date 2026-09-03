import SwiftUI

/// Translates between the two clocks the app juggles.
///
/// Solar Manager labels its timestamps `…Z`, but `RestDateHelper` parses them
/// in the local time zone, so every instant it returns sits one time-zone
/// offset in the past — and every request string it writes is read back the
/// same way. The chart series already undo that for their marks by calling
/// `convertToLocalTime()`, which means everything on a chart's x axis is a
/// real instant. Windows, scroll positions and axis labels therefore work in
/// real time, and only requests and raw sample dates need converting.
enum ChartPlotSpace {

    private static var offset: TimeInterval {
        TimeInterval(TimeZone.current.secondsFromGMT())
    }

    /// A real instant, expressed the way the API reads and writes it.
    static func toApi(_ date: Date) -> Date {
        date.addingTimeInterval(-offset)
    }

    /// A date straight off the API, as the real instant it stands for. Same
    /// transform the chart series apply to their marks.
    static func fromApi(_ date: Date) -> Date {
        date.addingTimeInterval(offset)
    }
}
