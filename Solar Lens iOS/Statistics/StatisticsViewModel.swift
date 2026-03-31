internal import Foundation
import SwiftUI

@Observable
class StatisticsViewModel {
    var todayData: MainData?
    var batteryHistory: [BatteryHistory]?
    var dailyStats: [DayStatistic]?
    var monthlyStats: [DayStatistic]?
    var yearlyStats: [DayStatistic]?
    var statistics: Statistics?
    var overallStatistics: Statistics?
    var isLoading = false
    var errorMessage: String?
    var batteryCharged: Double = 0
    var batteryDischarged: Double = 0
    var carCharged: Double? = nil
    var isCurrentlyCharging: Bool = false

    var selectedPeriod: StatisticsPeriod = .today
    var customStartDate: Date = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    var customEndDate: Date = Date()
    var customResolution: CustomResolution = .day
    var customStats: [DayStatistic]?

    private let energyManager: EnergyManager

    init(energyManager: EnergyManager = SolarManager.shared) {
        self.energyManager = energyManager
    }

    @MainActor
    func fetch() async {
        if isLoading { return }

        isLoading = true
        errorMessage = nil

        switch selectedPeriod {
        case .today:
            await fetchToday()
        case .week:
            await fetchWeek()
        case .month:
            await fetchMonth()
        case .year:
            await fetchYear()
        case .overall:
            await fetchOverall()
        case .custom:
            await fetchCustomRange()
        }

        isLoading = false
    }

    @MainActor
    private func fetchToday() async {
        todayData = try? await energyManager.fetchMainData(
            from: Date.todayStartOfDay(),
            to: Date.todayEndOfDay()
        )
        batteryHistory = try? await energyManager.fetchTodaysBatteryHistory()
        statistics = try? await energyManager.fetchStatistics(
            from: Date.todayStartOfDay(),
            to: Date.todayEndOfDay(),
            accuracy: .high
        )
        computeBatteryTotals(from: todayData?.data ?? [])
        await fetchCarCharging(period: .day)
        dailyStats = nil
        monthlyStats = nil
        customStats = nil
    }

    @MainActor
    private func fetchWeek() async {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .day, value: -7, to: Date.todayStartOfDay())!

        let mainData = try? await energyManager.fetchMainData(
            from: start,
            to: Date.todayEndOfDay(),
            interval: 300
        )
        if let mainData {
            dailyStats = calculateDailyStatistics(dataPoints: mainData.data)
            computeBatteryTotals(from: mainData.data)
        }
        await fetchCarCharging(period: .week)
        statistics = try? await energyManager.fetchStatistics(
            from: start,
            to: Date(),
            accuracy: .medium
        )
        todayData = nil
        monthlyStats = nil
        customStats = nil
    }

    @MainActor
    private func fetchMonth() async {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .month, value: -1, to: Date.todayStartOfDay())!

        let mainData = try? await energyManager.fetchMainData(
            from: start,
            to: Date.todayEndOfDay(),
            interval: 300
        )
        if let mainData {
            dailyStats = calculateDailyStatistics(dataPoints: mainData.data)
            computeBatteryTotals(from: mainData.data)
        }
        await fetchCarCharging(period: .month)
        statistics = try? await energyManager.fetchStatistics(
            from: start,
            to: Date(),
            accuracy: .medium
        )
        todayData = nil
        monthlyStats = nil
        customStats = nil
    }

    @MainActor
    private func fetchYear() async {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .year, value: -1, to: Date.todayStartOfDay())!

        // Fetch monthly statistics by fetching each month individually
        var months: [DayStatistic] = []
        var monthStart = start
        while monthStart < Date() {
            let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!
            let end = min(monthEnd, Date())
            let monthStats = try? await energyManager.fetchStatistics(
                from: monthStart,
                to: end,
                accuracy: .low
            )
            if let monthStats {
                let selfConsumption = monthStats.selfConsumption ?? 0
                let production = monthStats.production ?? 0
                let consumption = monthStats.consumption ?? 0
                months.append(DayStatistic(
                    day: monthStart,
                    consumption: consumption,
                    production: production,
                    imported: max(0, consumption - selfConsumption),
                    exported: max(0, production - selfConsumption)
                ))
            }
            monthStart = monthEnd
        }
        monthlyStats = months

        statistics = try? await energyManager.fetchStatistics(
            from: start,
            to: Date(),
            accuracy: .low
        )

        // Fetch battery data for the year (daily intervals)
        let mainData = try? await energyManager.fetchMainData(
            from: start,
            to: Date.todayEndOfDay(),
            interval: 86400
        )
        computeBatteryTotals(from: mainData?.data ?? [])

        // Car charging API only supports day/week/month — no yearly data available
        carCharged = nil

        todayData = nil
        dailyStats = nil
        customStats = nil
    }

    @MainActor
    private func fetchOverall() async {
        overallStatistics = try? await energyManager.fetchStatistics(
            from: nil,
            to: Date(),
            accuracy: .low
        )

        // Fetch per-year statistics going back up to 10 years
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        var years: [DayStatistic] = []

        for year in (currentYear - 10)...currentYear {
            var startComponents = DateComponents()
            startComponents.year = year
            startComponents.month = 1
            startComponents.day = 1
            guard let yearStart = calendar.date(from: startComponents) else { continue }

            var endComponents = DateComponents()
            endComponents.year = year
            endComponents.month = 12
            endComponents.day = 31
            endComponents.hour = 23
            endComponents.minute = 59
            endComponents.second = 59
            let yearEnd = min(calendar.date(from: endComponents) ?? Date(), Date())

            let yearStats = try? await energyManager.fetchStatistics(
                from: yearStart,
                to: yearEnd,
                accuracy: .low
            )
            if let yearStats, (yearStats.production ?? 0) > 0 || (yearStats.consumption ?? 0) > 0 {
                let selfConsumption = yearStats.selfConsumption ?? 0
                let production = yearStats.production ?? 0
                let consumption = yearStats.consumption ?? 0
                years.append(DayStatistic(
                    day: yearStart,
                    consumption: consumption,
                    production: production,
                    imported: max(0, consumption - selfConsumption),
                    exported: max(0, production - selfConsumption)
                ))
            }
        }
        yearlyStats = years

        batteryCharged = 0
        batteryDischarged = 0
        carCharged = nil

        todayData = nil
        dailyStats = nil
        monthlyStats = nil
        customStats = nil
        statistics = nil
    }

    @MainActor
    private func fetchCustomRange() async {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: customStartDate)
        let end = calendar.date(
            bySettingHour: 23, minute: 59, second: 59,
            of: customEndDate
        )!

        let daysBetween = calendar.dateComponents([.day], from: start, to: end).day ?? 0

        switch customResolution {
        case .day, .week:
            // Fetch raw data points and aggregate by day or week
            let interval = daysBetween <= 7 ? 300 : (daysBetween <= 90 ? 3600 : 86400)
            let mainData = try? await energyManager.fetchMainData(
                from: start,
                to: end,
                interval: interval
            )
            if let mainData {
                customStats = aggregateDataPoints(
                    mainData.data,
                    by: customResolution.calendarComponent
                )
                computeBatteryTotals(from: mainData.data)
            }

        case .month, .year:
            // Fetch per-period statistics via the statistics endpoint
            customStats = await fetchAggregatedStatistics(
                from: start,
                to: end,
                by: customResolution.calendarComponent
            )
            batteryCharged = 0
            batteryDischarged = 0
        }

        carCharged = nil

        let accuracy: Accuracy = daysBetween <= 7 ? .high : (daysBetween <= 90 ? .medium : .low)
        statistics = try? await energyManager.fetchStatistics(
            from: start,
            to: end,
            accuracy: accuracy
        )
        todayData = nil
        dailyStats = nil
        monthlyStats = nil
    }

    private func aggregateDataPoints(
        _ dataPoints: [MainDataItem],
        by component: Calendar.Component
    ) -> [DayStatistic] {
        let calendar = Calendar.current
        var buckets: [Date: [MainDataItem]] = [:]

        for point in dataPoints {
            let bucketStart: Date
            if component == .weekOfYear {
                // Align to start of ISO week
                let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: point.date)
                bucketStart = calendar.date(from: comps) ?? calendar.startOfDay(for: point.date)
            } else {
                let comps = calendar.dateComponents(
                    component == .day ? [.year, .month, .day] : [.year, .month],
                    from: point.date
                )
                bucketStart = calendar.date(from: comps) ?? calendar.startOfDay(for: point.date)
            }
            buckets[bucketStart, default: []].append(point)
        }

        return buckets.map { (bucketDate, items) in
            DayStatistic(
                day: bucketDate,
                consumption: items.reduce(0.0) { $0 + $1.consumptionOverTimeWatthours },
                production: items.reduce(0.0) { $0 + $1.productionOverTimeWatthours },
                imported: items.reduce(0.0) { $0 + $1.importedOverTimeWhatthours },
                exported: items.reduce(0.0) { $0 + $1.exportedOverTimeWhatthours }
            )
        }.sorted { $0.day < $1.day }
    }

    private func fetchAggregatedStatistics(
        from start: Date,
        to end: Date,
        by component: Calendar.Component
    ) async -> [DayStatistic] {
        let calendar = Calendar.current
        var results: [DayStatistic] = []
        var periodStart = start

        while periodStart < end {
            let periodEnd = calendar.date(byAdding: component, value: 1, to: periodStart)!
            let clampedEnd = min(periodEnd, end)
            let stats = try? await energyManager.fetchStatistics(
                from: periodStart,
                to: clampedEnd,
                accuracy: .low
            )
            if let stats {
                let selfConsumption = stats.selfConsumption ?? 0
                let production = stats.production ?? 0
                let consumption = stats.consumption ?? 0
                results.append(DayStatistic(
                    day: periodStart,
                    consumption: consumption,
                    production: production,
                    imported: max(0, consumption - selfConsumption),
                    exported: max(0, production - selfConsumption)
                ))
            }
            periodStart = periodEnd
        }

        return results
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

    private func computeBatteryTotals(from dataPoints: [MainDataItem]) {
        batteryCharged = dataPoints.reduce(0) { $0 + $1.batteryChargedWh }
        batteryDischarged = dataPoints.reduce(0) { $0 + $1.batteryDischargedWh }
    }

    @MainActor
    private func fetchCarCharging(period: Period) async {
        let chargingData = try? await energyManager.fetchChargingData()
        isCurrentlyCharging = (chargingData?.currentCharging ?? 0) > 0
        carCharged = (try? await energyManager.fetchCarChargingTotal(period: period)) ?? 0
    }

    private func calculateDailyStatistics(dataPoints: [MainDataItem]) -> [DayStatistic] {
        let calendar = Calendar.current
        var dataPointsByDay: [Date: [MainDataItem]] = [:]

        for dataPoint in dataPoints {
            let dayStart = calendar.startOfDay(for: dataPoint.date)
            dataPointsByDay[dayStart, default: []].append(dataPoint)
        }

        return dataPointsByDay.map { (day, items) in
            DayStatistic(
                day: day,
                consumption: items.reduce(0.0) { $0 + $1.consumptionOverTimeWatthours },
                production: items.reduce(0.0) { $0 + $1.productionOverTimeWatthours },
                imported: items.reduce(0.0) { $0 + $1.importedOverTimeWhatthours },
                exported: items.reduce(0.0) { $0 + $1.exportedOverTimeWhatthours }
            )
        }.sorted { $0.day < $1.day }
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
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"

    var id: String { rawValue }

    var localizedName: LocalizedStringKey {
        switch self {
        case .day: "Day"
        case .week: "Week"
        case .month: "Month"
        case .year: "Year"
        }
    }

    var calendarComponent: Calendar.Component {
        switch self {
        case .day: .day
        case .week: .weekOfYear
        case .month: .month
        case .year: .year
        }
    }

    var chartXUnit: Calendar.Component {
        switch self {
        case .day: .day
        case .week: .weekOfYear
        case .month: .month
        case .year: .year
        }
    }

    var chartXLabelFormat: XLabelFormat {
        switch self {
        case .day: .dayOfMonth
        case .week: .isoWeekNumber
        case .month: .monthNarrow
        case .year: .year
        }
    }
}
