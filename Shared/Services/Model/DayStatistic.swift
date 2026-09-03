internal import Foundation

struct DayStatistic {
    var day: Date
    var consumption: Double
    var production: Double
    var imported: Double
    var exported: Double

    /// Battery throughput of the bucket. Only filled where the figures come
    /// from raw samples; the statistics endpoint does not report them, so
    /// month- and year-sized buckets leave these at zero.
    var batteryCharged: Double = 0
    var batteryDischarged: Double = 0
}
