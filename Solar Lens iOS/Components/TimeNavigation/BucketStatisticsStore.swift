import SwiftUI

/// Bucket cache behind the scrollable statistics bar charts.
///
/// The Statistics tab used to fetch exactly the period it showed and throw it
/// away on every switch. Scrolling needs the opposite: buckets accumulate as
/// the user walks backwards, so a scroll over ground already covered costs
/// nothing.
///
/// Day and week buckets come from raw samples (one request per calendar
/// month); month and year buckets come from the statistics endpoint, one
/// request each — the same trade the screen made before.
///
/// iOS only.
@Observable
final class BucketStatisticsStore {

    enum Bucket: Equatable {
        case day
        case week
        case month
        case year

        var calendarComponent: Calendar.Component {
            switch self {
            case .day: .day
            case .week: .weekOfYear
            case .month: .month
            case .year: .year
            }
        }

        /// Whether the buckets are aggregated from raw samples rather than
        /// fetched one statistics call at a time.
        var derivesFromSamples: Bool {
            self == .day || self == .week
        }
    }

    private(set) var isLoading = false

    /// How long a bucket that is still running stays fresh.
    private static let openBucketMaxAge: TimeInterval = 60

    private let energyManager: EnergyManager
    private let calendar = Calendar.current

    /// Daily figures aggregated from raw samples, keyed by start of day.
    private var daily: [Date: DayStatistic] = [:]
    /// Calendar months whose raw samples have been fetched, and when.
    private var loadedMonths: [Date: Date] = [:]

    /// Month- and year-sized buckets, keyed by bucket start.
    private var periods: [Date: DayStatistic] = [:]
    private var loadedPeriods: [Date: Date] = [:]

    init(energyManager: EnergyManager = SolarManager.shared) {
        self.energyManager = energyManager
    }

    // MARK: - Reading

    /// The buckets covering `range`, oldest first. Missing ones are simply
    /// absent — the chart draws the gap rather than a fake zero.
    func buckets(in range: Range<Date>, bucket: Bucket) -> [DayStatistic] {
        switch bucket {
        case .day:
            return daily
                .filter { range.contains($0.key) }
                .values
                .sorted { $0.day < $1.day }
        case .week:
            return weekBuckets(in: range)
        case .month, .year:
            return periods
                .filter { range.contains($0.key) }
                .values
                .sorted { $0.day < $1.day }
        }
    }

    /// Sum of every bucket in `range` — the figures behind the totals cards.
    func total(in range: Range<Date>, bucket: Bucket) -> DayStatistic {
        buckets(in: range, bucket: bucket)
            .reduce(
                DayStatistic(
                    day: range.lowerBound, consumption: 0, production: 0,
                    imported: 0, exported: 0
                )
            ) { acc, item in
                DayStatistic(
                    day: acc.day,
                    consumption: acc.consumption + item.consumption,
                    production: acc.production + item.production,
                    imported: acc.imported + item.imported,
                    exported: acc.exported + item.exported,
                    batteryCharged: acc.batteryCharged + item.batteryCharged,
                    batteryDischarged: acc.batteryDischarged + item.batteryDischarged
                )
            }
    }

    // MARK: - Loading

    @MainActor
    func ensureLoaded(_ range: Range<Date>, bucket: Bucket) async {
        let upper = min(range.upperBound, Date())
        guard range.lowerBound < upper else { return }

        isLoading = true
        defer { isLoading = false }

        if bucket.derivesFromSamples {
            await loadSamples(from: range.lowerBound, to: upper)
        } else {
            await loadPeriods(
                from: range.lowerBound, to: upper,
                component: bucket.calendarComponent
            )
        }
    }

    // MARK: - Sample-derived buckets

    @MainActor
    private func loadSamples(from start: Date, to end: Date) async {
        // Consecutive missing months are fetched in one request. Scrolling adds
        // a month at a time, but the first look at a long custom range would
        // otherwise cost a request per month.
        for run in missingMonthRuns(from: start, to: end) {
            // The caller restarts this task on every scroll; stop as soon as a
            // newer window has superseded this one.
            if Task.isCancelled { return }

            let runEnd = min(run.upperBound, Date())
            guard run.lowerBound < runEnd else { continue }

            // The figures are watt-hours *per interval*, so a coarser interval
            // sums to the same daily total for a fraction of the payload. Long
            // runs go straight to one sample per day.
            let months = calendar.dateComponents(
                [.month], from: run.lowerBound, to: run.upperBound
            ).month ?? 1
            let interval = months > 2 ? 86400 : 3600

            // The run bounds are real instants; the API reads and writes them
            // one time-zone offset earlier — see `ChartPlotSpace`.
            guard
                let data = try? await energyManager.fetchMainData(
                    from: ChartPlotSpace.toApi(run.lowerBound),
                    to: ChartPlotSpace.toApi(runEnd),
                    interval: interval
                )
            else { continue }

            let grouped = Dictionary(
                grouping: data.data,
                by: { calendar.startOfDay(for: ChartPlotSpace.fromApi($0.date)) }
            )
            for (day, samples) in grouped {
                daily[day] = DayStatistic(
                    day: day,
                    consumption: samples.reduce(0) { $0 + $1.consumptionOverTimeWatthours },
                    production: samples.reduce(0) { $0 + $1.productionOverTimeWatthours },
                    imported: samples.reduce(0) { $0 + $1.importedOverTimeWhatthours },
                    exported: samples.reduce(0) { $0 + $1.exportedOverTimeWhatthours },
                    batteryCharged: samples.reduce(0) { $0 + $1.batteryChargedWh },
                    batteryDischarged: samples.reduce(0) { $0 + $1.batteryDischargedWh }
                )
            }

            let fetchedAt = Date()
            var month = run.lowerBound
            while month < run.upperBound {
                loadedMonths[month] = fetchedAt
                guard let next = calendar.date(byAdding: .month, value: 1, to: month) else { break }
                month = next
            }
        }
    }

    /// Runs of adjacent calendar months that still need fetching.
    private func missingMonthRuns(from start: Date, to end: Date) -> [Range<Date>] {
        var runs: [Range<Date>] = []
        var runStart: Date?

        for month in months(from: start, to: end) {
            let monthEnd = calendar.date(byAdding: .month, value: 1, to: month) ?? end
            if needsFetch(month, end: monthEnd, in: loadedMonths) {
                if runStart == nil { runStart = month }
            } else if let open = runStart {
                runs.append(open..<month)
                runStart = nil
            }
        }
        if let open = runStart {
            let last = calendar.date(from: calendar.dateComponents([.year, .month], from: end))
            let closing = calendar.date(byAdding: .month, value: 1, to: last ?? end) ?? end
            runs.append(open..<max(closing, open.addingTimeInterval(60)))
        }
        return runs
    }

    private func weekBuckets(in range: Range<Date>) -> [DayStatistic] {
        let isoCalendar = Calendar(identifier: .iso8601)
        var grouped: [Date: DayStatistic] = [:]

        for (day, stat) in daily {
            let comps = isoCalendar.dateComponents(
                [.yearForWeekOfYear, .weekOfYear], from: day
            )
            guard let weekStart = isoCalendar.date(from: comps),
                range.contains(weekStart)
            else { continue }

            var bucket =
                grouped[weekStart]
                ?? DayStatistic(
                    day: weekStart, consumption: 0, production: 0,
                    imported: 0, exported: 0
                )
            bucket.consumption += stat.consumption
            bucket.production += stat.production
            bucket.imported += stat.imported
            bucket.exported += stat.exported
            bucket.batteryCharged += stat.batteryCharged
            bucket.batteryDischarged += stat.batteryDischarged
            grouped[weekStart] = bucket
        }

        return grouped.values.sorted { $0.day < $1.day }
    }

    // MARK: - Statistics-endpoint buckets

    @MainActor
    private func loadPeriods(
        from start: Date, to end: Date, component: Calendar.Component
    ) async {
        var bucketStart = align(start, to: component)
        while bucketStart < end {
            // The caller restarts this task on every scroll; stop as soon as a
            // newer window has superseded this one.
            if Task.isCancelled { return }

            defer {
                bucketStart =
                    calendar.date(byAdding: component, value: 1, to: bucketStart)
                    ?? end
            }
            let fullEnd =
                calendar.date(byAdding: component, value: 1, to: bucketStart) ?? end
            guard needsFetch(bucketStart, end: fullEnd, in: loadedPeriods) else { continue }

            let bucketEnd = min(fullEnd, Date())
            guard bucketStart < bucketEnd else { continue }

            guard
                let stats = try? await energyManager.fetchStatistics(
                    from: ChartPlotSpace.toApi(bucketStart),
                    to: ChartPlotSpace.toApi(bucketEnd),
                    accuracy: .low
                )
            else { continue }

            loadedPeriods[bucketStart] = Date()

            let selfConsumption = stats.selfConsumption ?? 0
            let production = stats.production ?? 0
            let consumption = stats.consumption ?? 0

            // A bucket from before the installation existed reports nothing.
            // Leave it out rather than drawing a row of zero-height bars.
            guard production > 0 || consumption > 0 else { continue }

            periods[bucketStart] = DayStatistic(
                day: bucketStart,
                consumption: consumption,
                production: production,
                imported: max(0, consumption - selfConsumption),
                exported: max(0, production - selfConsumption)
            )
        }
    }

    // MARK: - Helpers

    /// A bucket that had already ended when it was fetched never changes; one
    /// that was still running is re-fetched once it goes stale.
    private func needsFetch(
        _ bucketStart: Date, end bucketEnd: Date, in loaded: [Date: Date]
    ) -> Bool {
        guard let fetchedAt = loaded[bucketStart] else { return true }
        guard bucketEnd > fetchedAt else { return false }
        return Date().timeIntervalSince(fetchedAt) > Self.openBucketMaxAge
    }

    private func align(_ date: Date, to component: Calendar.Component) -> Date {
        let units: Set<Calendar.Component> =
            component == .year ? [.year] : [.year, .month]
        return calendar.date(from: calendar.dateComponents(units, from: date))
            ?? calendar.startOfDay(for: date)
    }

    private func months(from start: Date, to end: Date) -> [Date] {
        var result: [Date] = []
        var month = align(start, to: .month)
        while month < end {
            result.append(month)
            guard let next = calendar.date(byAdding: .month, value: 1, to: month) else { break }
            month = next
        }
        return result
    }
}
