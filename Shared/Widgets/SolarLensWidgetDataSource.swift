internal import Foundation

class SolarLensWidgetDataSource {
    private let solarManager = SolarManager.shared
    private var lastFetchOverviewData: Date?
    private var lastFetchSolarData: Date?
    private var lastFetchConsumptionData: Date?
    private var overviewData: OverviewData?
    private var solarData: SolarDetailsData?
    private var consumptionData: MainData?

    func getOverviewData() async throws -> OverviewData? {

        if overviewData == nil
            || lastFetchOverviewData?.timeIntervalSinceNow ?? 0 < -4 * 60
        {
            // Widgets consume today's statistics fields (e.g. the
            // efficiency widget reads todaySelfConsumptionRate and
            // todayAutarchyDegree). Since `fetchOverviewData` no longer
            // includes them, fetch both in parallel and merge.
            async let corePromise = solarManager.fetchOverviewData(
                lastOverviewData: overviewData)
            async let statsPromise = solarManager.fetchTodayStatistics()

            let data = try? await corePromise
            if let data {
                if let stats = try? await statsPromise {
                    data.todaySelfConsumption = stats.selfConsumption
                    data.todaySelfConsumptionRate = stats.selfConsumptionRate
                    data.todayAutarchyDegree = stats.autarchyDegree
                    data.todayProduction = stats.production
                    data.todayConsumption = stats.consumption
                }
            }

            overviewData = data
            lastFetchOverviewData = Date()
            print(
                "\(Date().formatted(.iso8601)) - Fetched overview data for widget"
            )
        }

        return overviewData
    }

    func getSolarProductionData() async throws -> SolarDetailsData? {

        if solarData == nil
            || lastFetchSolarData?.timeIntervalSinceNow ?? 0 < -4 * 60
        {
            let data = try? await solarManager.fetchSolarDetails()

            solarData = data
            lastFetchSolarData = Date()
            print(
                "\(Date().formatted(.iso8601)) - Fetched solar data for widget")
        }

        return solarData
    }
    
    func getComsumptionData() async throws -> MainData? {

        if consumptionData == nil
            || lastFetchConsumptionData?.timeIntervalSinceNow ?? 0 < -4 * 60
        {
            let data = try? await solarManager.fetchMainData(
                from: Date.todayStartOfDay(), to: Date.todayEndOfDay())

            consumptionData = data
            lastFetchConsumptionData = Date()
            print(
                "\(Date().formatted(.iso8601)) - Fetched consumption data for widget"
            )
        }

        return consumptionData
    }

}
