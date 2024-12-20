import Foundation

class SolarLensWidgetDataSource {
    private let solarManager = SolarManager()
    private var lastFetchOverviewData: Date?
    private var lastFetchSolarData: Date?
    private var overviewData: OverviewData?
    private var solarData: SolarDetailsData?

    func getOverviewData() async throws -> OverviewData? {
        
        if overviewData == nil || lastFetchOverviewData?.timeIntervalSinceNow ?? 0 < -4*60 {
            let data = try? await solarManager.fetchOverviewData(
                lastOverviewData: overviewData)

            overviewData = data;
            lastFetchOverviewData = Date()
            print("\(Date().formatted(.iso8601)) - Fetched overview data for widget")
        }
        
        return overviewData;
    }
    
    func getSolarProductionData() async throws -> SolarDetailsData? {
        
        if solarData == nil || lastFetchSolarData?.timeIntervalSinceNow ?? 0 < -4*60 {
            let data = try? await solarManager.fetchSolarDetails()

            solarData = data;
            lastFetchSolarData = Date()
            print("\(Date().formatted(.iso8601)) - Fetched solar data for widget")
        }
        
        return solarData;
    }
}
