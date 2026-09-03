internal import Foundation
import SwiftUI

@Observable
class StatisticsViewModel {

    // MARK: - Selection

    var selectedPeriod: StatisticsPeriod = .today
    var customStartDate: Date = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    var customEndDate: Date = Date()
    var customResolution: CustomResolution = .day

    // MARK: - Time navigation

    /// Drives the visible window of the scrollable chart. Replaced whenever
    /// the period changes, because each period scrolls in its own unit.
    /// `nil` for the custom range, where the date pickers are the control and
    /// `stepCustomRange(by:)` does the paging.
    private(set) var navigator: ChartTimeNavigator?

    /// Registration date of the Solar Manager installation — nothing exists
    /// before it, so the chart stops scrolling there.
    private(set) var earliestDate: Date?

    // MARK: - Data

    let intraday: IntradayChartStore
    let buckets: BucketStatisticsStore

    /// Rates for the visible window: self-consumption and autarky can only
    /// come from the statistics endpoint, they are not derivable from the
    /// per-interval samples.
    var windowRates: Statistics?

    var carCharged: Double?
    var heatpumpConsumed: Double?
    var boilerConsumed: Double?

    /// Set when the visible window is too long to sample the per-device
    /// endpoint — car charging, heat pump and boiler have no aggregate API
    /// for an arbitrary range, so their cards stay hidden.
    var auxTotalsUnavailable = false

    var isCurrentlyCharging = false
    var isLoadingTotals = false

    /// Lifetime production, for the eco meter on the Overall page. Deliberately
    /// independent of the visible window — "trees saved" is a whole-installation
    /// figure, not a per-window one.
    var lifetimeStatistics: Statistics?

    private let energyManager: EnergyManager
    private let calendar = Calendar.current

    init(energyManager: EnergyManager = SolarManager.shared) {
        self.energyManager = energyManager
        self.intraday = IntradayChartStore(energyManager: energyManager)
        self.buckets = BucketStatisticsStore(energyManager: energyManager)
        self.navigator = Self.makeNavigator(for: .today, earliest: nil)
    }

    var isLoading: Bool {
        intraday.isLoading || buckets.isLoading
    }

    // MARK: - Window

    /// The range the chart currently shows.
    var window: Range<Date> {
        if let navigator { return navigator.window }
        return customWindow
    }

    var customWindow: Range<Date> {
        let start = calendar.startOfDay(for: customStartDate)
        let end =
            calendar.date(
                bySettingHour: 23, minute: 59, second: 59, of: customEndDate
            ) ?? customEndDate
        return start..<max(end, start.addingTimeInterval(60))
    }

    /// Label describing the visible window, shown between the ‹ › buttons.
    var windowLabel: String {
        if let navigator { return navigator.windowLabel }
        let from = customWindow.lowerBound.formatted(.dateTime.day().month(.abbreviated))
        let to = customWindow.upperBound.formatted(.dateTime.day().month(.abbreviated).year())
        return "\(from) – \(to)"
    }

    /// What to have loaded: the visible window, plus head-room where head-room
    /// is cheap. Day buckets arrive a calendar month at a time, so a page of
    /// look-ahead costs almost nothing. Month and year buckets cost one
    /// statistics request each, so those fetch only what is on screen and let
    /// the next scroll pull the rest.
    var loadRange: Range<Date> {
        guard let navigator else { return customWindow }
        switch selectedPeriod {
        case .today, .week, .month:
            return navigator.window(withHeadroom: 1)
        case .year, .overall, .custom:
            return navigator.window
        }
    }

    /// Which bucket size the bar chart draws, `nil` for the intraday chart.
    var bucket: BucketStatisticsStore.Bucket? {
        switch selectedPeriod {
        case .today: nil
        case .week, .month: .day
        case .year: .month
        case .overall: .year
        case .custom: customResolution.bucket
        }
    }

    // MARK: - Chart data

    /// Buckets across the whole loaded range — the bar chart's marks.
    var loadedBuckets: [DayStatistic] {
        guard let bucket else { return [] }
        return buckets.buckets(in: loadRange, bucket: bucket)
    }

    /// Buckets inside the visible window — axis density and the y scale.
    var visibleBuckets: [DayStatistic] {
        guard let bucket else { return [] }
        return buckets.buckets(in: window, bucket: bucket)
    }

    // MARK: - Totals

    /// The totals cards' figures, summed over the visible window. Production
    /// and consumption come from the buckets or samples on hand; the rates
    /// come from the statistics endpoint.
    var windowStatistics: Statistics {
        let sums = windowSums
        return Statistics(
            consumption: sums.consumption,
            production: sums.production,
            selfConsumption: windowRates?.selfConsumption
                ?? max(0, sums.production - sums.exported),
            selfConsumptionRate: windowRates?.selfConsumptionRate,
            autarchyDegree: windowRates?.autarchyDegree
        )
    }

    var batteryCharged: Double { windowSums.batteryCharged }
    var batteryDischarged: Double { windowSums.batteryDischarged }

    /// Whether battery throughput can be reported for the visible window at
    /// all. Month- and year-sized buckets come from the statistics endpoint,
    /// which does not carry it — showing "0.0 MWh" there would read as "the
    /// battery did nothing all year".
    var batteryFiguresAvailable: Bool {
        guard let bucket else { return true }
        return bucket.derivesFromSamples
    }

    /// Measured grid figures, available wherever the buckets come from raw
    /// samples. Month- and year-sized buckets only have the statistics
    /// endpoint's self-consumption to derive them from, so they return `nil`
    /// and let the cards do that derivation.
    var measuredGrid: (imported: Double, exported: Double)? {
        if let bucket, !bucket.derivesFromSamples { return nil }
        let sums = windowSums
        return (sums.imported, sums.exported)
    }

    private var windowSums: DayStatistic {
        if let bucket {
            return buckets.total(in: window, bucket: bucket)
        }
        let samples = intraday.items(in: window)
        return DayStatistic(
            day: window.lowerBound,
            consumption: samples.reduce(0) { $0 + $1.consumptionOverTimeWatthours },
            production: samples.reduce(0) { $0 + $1.productionOverTimeWatthours },
            imported: samples.reduce(0) { $0 + $1.importedOverTimeWhatthours },
            exported: samples.reduce(0) { $0 + $1.exportedOverTimeWhatthours },
            batteryCharged: samples.reduce(0) { $0 + $1.batteryChargedWh },
            batteryDischarged: samples.reduce(0) { $0 + $1.batteryDischargedWh }
        )
    }

    // MARK: - Period changes

    func periodChanged() {
        navigator =
            selectedPeriod == .custom
            ? nil
            : Self.makeNavigator(for: selectedPeriod, earliest: earliestDate)
        windowRates = nil
        carCharged = nil
        heatpumpConsumed = nil
        boilerConsumed = nil
        auxTotalsUnavailable = false
    }

    /// Moves the custom range by its own length. The date pickers stay the
    /// control for *how long* the window is; this moves *where* it sits.
    func stepCustomRange(by pages: Int) {
        let length = customWindow.upperBound.timeIntervalSince(customWindow.lowerBound)
        let shift = length * Double(pages)
        let newStart = customStartDate.addingTimeInterval(shift)
        let newEnd = customEndDate.addingTimeInterval(shift)
        guard newEnd <= Date() || pages < 0 else { return }
        if let earliestDate, newStart < earliestDate { return }
        customStartDate = newStart
        customEndDate = min(newEnd, Date())
    }

    var canStepCustomForward: Bool {
        customWindow.upperBound < Date()
    }

    var canStepCustomBack: Bool {
        guard let earliestDate else { return true }
        return customWindow.lowerBound > earliestDate
    }

    private static func makeNavigator(
        for period: StatisticsPeriod, earliest: Date?
    ) -> ChartTimeNavigator {
        switch period {
        case .today:
            return ChartTimeNavigator(page: .day, earliest: earliest)
        case .week:
            return ChartTimeNavigator(page: .week, earliest: earliest)
        case .month:
            return ChartTimeNavigator(page: .month, earliest: earliest)
        case .year:
            return ChartTimeNavigator(page: .year, earliest: earliest)
        case .overall, .custom:
            return ChartTimeNavigator(page: .decade, earliest: earliest)
        }
    }

    // MARK: - Loading

    @MainActor
    func loadWindow() async {
        if let bucket {
            await buckets.ensureLoaded(loadRange, bucket: bucket)
        } else {
            await intraday.ensureLoaded(around: window)
        }
    }

    /// The figures that cannot be derived from the chart data: the rates and
    /// the per-device consumers. One pass per settled window.
    @MainActor
    func loadTotals() async {
        let range = window
        let end = min(range.upperBound, Date())
        guard range.lowerBound < end else { return }

        isLoadingTotals = true
        defer { isLoadingTotals = false }

        let days = calendar.dateComponents(
            [.day], from: range.lowerBound, to: end
        ).day ?? 0
        let accuracy: Accuracy = days <= 7 ? .high : (days <= 90 ? .medium : .low)

        // The window is in real time; the API reads its bounds one time-zone
        // offset earlier — see `ChartPlotSpace`.
        windowRates = try? await energyManager.fetchStatistics(
            from: ChartPlotSpace.toApi(range.lowerBound),
            to: ChartPlotSpace.toApi(end),
            accuracy: accuracy
        )

        if range.upperBound >= Date() {
            let charging = try? await energyManager.fetchChargingData()
            isCurrentlyCharging = (charging?.currentCharging ?? 0) > 0
        } else {
            isCurrentlyCharging = false
        }

        await loadAuxiliaryConsumers(from: range.lowerBound, to: end)
    }

    /// Car charging, heat pump and boiler totals. `/v1/consumption/sensor`
    /// only knows "day / week / month ending now", so these are summed from
    /// the per-device data endpoint instead — which caps out at a year.
    @MainActor
    private func loadAuxiliaryConsumers(from: Date, to: Date) async {
        let apiFrom = ChartPlotSpace.toApi(from)
        let apiTo = ChartPlotSpace.toApi(to)

        let car = try? await energyManager.fetchCarChargingTotal(from: apiFrom, to: apiTo)
        let heatpump = try? await energyManager.fetchHeatpumpTotal(from: apiFrom, to: apiTo)
        let boiler = try? await energyManager.fetchBoilerTotal(from: apiFrom, to: apiTo)

        // A nil from the manager means "range too long to sample", which is a
        // different thing from "no such device" (zero).
        auxTotalsUnavailable = (car ?? nil) == nil
        carCharged = car ?? nil
        heatpumpConsumed = heatpump ?? nil
        boilerConsumed = boiler ?? nil
    }

    @MainActor
    func loadLifetimeStatistics() async {
        guard lifetimeStatistics == nil else { return }
        lifetimeStatistics = try? await energyManager.fetchStatistics(
            from: nil, to: Date(), accuracy: .low
        )
    }

    @MainActor
    func loadEarliestDate() async {
        guard earliestDate == nil,
            let info = try? await energyManager.fetchServerInfo(),
            let registered = info.registrationDate
        else { return }
        earliestDate = registered
        navigator?.setEarliest(registered)
    }

    // MARK: - Export

    /// Rows for the CSV / XLSX export: exactly the buckets the user is
    /// looking at.
    var exportableData: [DayStatistic]? {
        guard bucket != nil else { return nil }
        let visible = visibleBuckets
        return visible.isEmpty ? nil : visible
    }

    /// High-resolution export for an hourly custom range — fetched on demand,
    /// since the chart itself only needs daily buckets.
    func intervalDataForExport() async -> [MainDataItem]? {
        guard selectedPeriod == .custom, customResolution == .hourly else { return nil }

        let range = customWindow
        var items: [MainDataItem] = []
        for chunk in DateRangeChunker.monthlyChunks(
            from: ChartPlotSpace.toApi(range.lowerBound),
            to: ChartPlotSpace.toApi(min(range.upperBound, Date()))
        ) {
            if let data = try? await energyManager.fetchMainData(
                from: chunk.start, to: chunk.end, interval: 3600
            ) {
                items.append(contentsOf: data.data)
            }
        }
        return items.isEmpty ? nil : items.sorted { $0.date < $1.date }
    }

    /// Derives grid import/export from overall Statistics (which only has selfConsumption)
    func deriveGridValues(from stats: Statistics) -> (imported: Double, exported: Double) {
        let selfConsumption = stats.selfConsumption ?? 0
        let production = stats.production ?? 0
        let consumption = stats.consumption ?? 0
        return (
            imported: max(0, consumption - selfConsumption),
            exported: max(0, production - selfConsumption)
        )
    }
}

enum StatisticsPeriod: String, CaseIterable, Identifiable {
    case today = "Today"
    case week = "Week"
    case month = "Month"
    case year = "Year"
    case overall = "Overall"
    case custom = "Custom"

    var id: String { rawValue }

    var localizedName: LocalizedStringKey {
        switch self {
        case .today: "Today"
        case .week: "Week"
        case .month: "Month"
        case .year: "Year"
        case .overall: "Overall"
        case .custom: "Custom"
        }
    }
}

enum CustomResolution: String, CaseIterable, Identifiable {
    case hourly = "Hourly"
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"

    var id: String { rawValue }

    var localizedName: LocalizedStringKey {
        switch self {
        case .hourly: "Hourly"
        case .day: "Day"
        case .week: "Week"
        case .month: "Month"
        case .year: "Year"
        }
    }

    var bucket: BucketStatisticsStore.Bucket {
        switch self {
        // Hourly samples are aggregated to days for the chart; the raw
        // resolution only matters for the export.
        case .hourly, .day: .day
        case .week: .week
        case .month: .month
        case .year: .year
        }
    }

    var chartXLabelFormat: XLabelFormat {
        switch self {
        case .hourly: .dayOfMonth
        case .day: .dayOfMonth
        case .week: .isoWeekNumber
        case .month: .monthNarrow
        case .year: .year
        }
    }
}
