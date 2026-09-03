import SwiftUI

/// Day-by-day cache behind the scrollable intraday charts.
///
/// The screens used to fetch "today" once. Now that the charts scroll back in
/// time, the data has to arrive in pieces and stay around: this keeps one
/// bucket per calendar day, hands out the merged series, and re-fetches only
/// today (which is still growing).
///
/// iOS only.
@Observable
final class IntradayChartStore {

    /// Merged, chronologically sorted samples across every loaded day.
    private(set) var items: [MainDataItem] = []

    /// Merged battery history, one entry per battery sensor.
    private(set) var batteries: [BatteryHistory] = []

    private(set) var isLoading = false

    /// How long today's bucket stays fresh before it is fetched again.
    private static let todayMaxAge: TimeInterval = 60

    private let energyManager: EnergyManager
    private let includeBatteryHistory: Bool
    private let calendar = Calendar.current

    private var samplesByDay: [Date: [MainDataItem]] = [:]
    private var batteriesByDay: [Date: [BatteryHistory]] = [:]
    private var fetchedAt: [Date: Date] = [:]

    init(
        energyManager: EnergyManager = SolarManager.shared,
        includeBatteryHistory: Bool = true
    ) {
        self.energyManager = energyManager
        self.includeBatteryHistory = includeBatteryHistory
    }

    /// Loads every day the given window touches, plus one day of head-room on
    /// each side so a scroll into the neighbouring page finds data already
    /// there. Days already cached are skipped.
    @MainActor
    func ensureLoaded(around window: Range<Date>) async {
        let padded = calendar.date(byAdding: .day, value: -1, to: window.lowerBound)
            ?? window.lowerBound
        let upper = calendar.date(byAdding: .day, value: 1, to: window.upperBound)
            ?? window.upperBound
        await ensureLoaded(days: padded..<upper)
    }

    /// Loads exactly the days `range` touches, skipping the ones already
    /// cached and anything in the future.
    @MainActor
    func ensureLoaded(days range: Range<Date>) async {
        let upper = min(range.upperBound, Date())
        guard range.lowerBound <= upper else { return }

        let wanted = days(from: range.lowerBound, to: upper).filter(needsFetch)
        guard !wanted.isEmpty else { return }

        isLoading = true
        defer { isLoading = false }

        for day in wanted {
            // The caller restarts this task on every scroll; stop as soon as a
            // newer window has superseded this one.
            if Task.isCancelled { break }
            await fetch(day: day)
        }
        rebuild()
    }

    /// The samples of one calendar day, empty when it was never loaded.
    func samples(on day: Date) -> [MainDataItem] {
        samplesByDay[calendar.startOfDay(for: day)] ?? []
    }

    /// Drops today's cached bucket so the next `ensureLoaded` re-fetches it.
    @MainActor
    func invalidateToday() {
        fetchedAt[calendar.startOfDay(for: Date())] = nil
    }

    // MARK: - Windowed slices

    /// The samples that fall inside `window`, for totals that have to follow
    /// what the user is actually looking at. `window` is in real time, the
    /// sample dates are not — see `ChartPlotSpace`.
    func items(in window: Range<Date>) -> [MainDataItem] {
        items.filter { window.contains(ChartPlotSpace.fromApi($0.date)) }
    }

    /// The samples a chart should actually draw. The chart pins its x domain to
    /// the window, so anything outside it would be laid out only to be clipped.
    func marks(around window: Range<Date>, paddingDays: Int = 0) -> [MainDataItem] {
        items(in: padded(window, by: paddingDays))
    }

    /// Battery history for the same window as `marks(around:)`.
    func batteryMarks(around window: Range<Date>, paddingDays: Int = 0) -> [BatteryHistory] {
        batteries(in: padded(window, by: paddingDays))
    }

    private func padded(_ window: Range<Date>, by days: Int) -> Range<Date> {
        let lower = calendar.date(byAdding: .day, value: -days, to: window.lowerBound)
            ?? window.lowerBound
        let upper = calendar.date(byAdding: .day, value: days, to: window.upperBound)
            ?? window.upperBound
        return lower..<upper
    }

    /// Battery history restricted to `window`, mirroring `items(in:)`.
    func batteries(in window: Range<Date>) -> [BatteryHistory] {
        batteries.compactMap { history in
            let inWindow = history.items.filter {
                window.contains(ChartPlotSpace.fromApi($0.date))
            }
            guard !inWindow.isEmpty else { return nil }
            return BatteryHistory(
                batterySensorId: history.batterySensorId,
                items: inWindow
            )
        }
    }

    // MARK: - Fetching

    private func needsFetch(_ day: Date) -> Bool {
        guard let fetched = fetchedAt[day] else { return true }
        guard calendar.isDateInToday(day) else { return false }
        return Date().timeIntervalSince(fetched) > Self.todayMaxAge
    }

    @MainActor
    private func fetch(day: Date) async {
        // The day is a real local day; the API reads and writes its bounds one
        // time-zone offset earlier — see `ChartPlotSpace`.
        let start = ChartPlotSpace.toApi(day)
        let end = ChartPlotSpace.toApi(
            calendar.date(byAdding: .day, value: 1, to: day) ?? day
        )

        async let mainTask = try? energyManager.fetchMainData(
            from: start, to: end, interval: 300
        )
        async let batteryTask = batteryHistory(from: start, to: end)

        let (main, battery) = await (mainTask, batteryTask)

        samplesByDay[day] = main?.data ?? []
        batteriesByDay[day] = battery
        fetchedAt[day] = Date()
    }

    private func batteryHistory(from: Date, to: Date) async -> [BatteryHistory] {
        guard includeBatteryHistory else { return [] }
        return (try? await energyManager.fetchBatteryHistory(from: from, to: to)) ?? []
    }

    private func rebuild() {
        items =
            samplesByDay
            .values
            .flatMap { $0 }
            .sorted { $0.date < $1.date }

        var merged: [String: [BatteryHistoryItem]] = [:]
        for histories in batteriesByDay.values {
            for history in histories {
                merged[history.batterySensorId, default: []]
                    .append(contentsOf: history.items)
            }
        }
        batteries = merged.map { sensorId, items in
            BatteryHistory(
                batterySensorId: sensorId,
                items: items.sorted { $0.date < $1.date }
            )
        }
    }

    private func days(from start: Date, to end: Date) -> [Date] {
        var result: [Date] = []
        var day = calendar.startOfDay(for: start)
        let last = calendar.startOfDay(for: end)
        while day <= last {
            result.append(day)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return result
    }
}
