internal import Foundation

/// Picks a sampling resolution and request split for `/v3/devices/{id}/data/range`.
///
/// The endpoint only accepts 10 / 300 / 900 second intervals, so a long range
/// turns into a lot of data points. This trades resolution for range — the
/// callers only ever sum the samples, so a coarser interval costs nothing but
/// keeps the payload sane — and refuses ranges beyond a year outright, where
/// even 900 s sampling would mean dozens of requests per device.
struct DeviceRangeSamplingPlan {

    /// Seconds between samples, one of the values the API accepts.
    let interval: Int

    /// `[start, end)` bounds to request, in order.
    let chunks: [(start: Date, end: Date)]

    /// The longest range worth sampling per device.
    private static let maximumRange: TimeInterval = 366 * 24 * 3600

    /// `nil` when the range is empty or too long to sample.
    init?(from: Date, to: Date) {
        guard from < to else { return nil }

        let length = to.timeIntervalSince(from)
        guard length <= Self.maximumRange else { return nil }

        let twoDays: TimeInterval = 2 * 24 * 3600
        let oneMonth: TimeInterval = 31 * 24 * 3600

        if length <= twoDays {
            interval = 300
            chunks = [(from, to)]
        } else if length <= oneMonth {
            interval = 900
            chunks = [(from, to)]
        } else {
            interval = 900
            chunks = DateRangeChunker.monthlyChunks(from: from, to: to)
        }
    }
}
