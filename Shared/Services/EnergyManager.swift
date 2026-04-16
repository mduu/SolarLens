import Combine
internal import Foundation

/// Aggregated statistics for the current day. Fetched separately from the
/// core overview so the home screen's live numbers can render before the
/// (typically slower) aggregation endpoint returns.
struct TodayStatistics: Sendable {
    let selfConsumption: Double?
    let selfConsumptionRate: Double?
    let autarchyDegree: Double?
    let production: Double?
    let consumption: Double?
}

protocol EnergyManager {
    func login(username: String, password: String) async -> Bool

    func fetchOverviewData(lastOverviewData: OverviewData?) async throws
        -> OverviewData

    /// Fetches today's aggregated statistics (self-consumption, autarchy,
    /// production/consumption totals). Intentionally split from
    /// `fetchOverviewData` so the home screen's live numbers can render
    /// before this typically-slower aggregation endpoint returns.
    func fetchTodayStatistics() async throws -> TodayStatistics?

    func fetchChargingData() async throws -> CharingInfoData

    func fetchCarChargingTotal(period: Period) async throws -> Double
    
    func fetchSolarDetails() async throws -> SolarDetailsData
    
    func fetchMainData(from: Date, to: Date, interval: Int) async throws -> MainData

    func fetchTodaysBatteryHistory() async throws -> [BatteryHistory]

    func fetchTariff() async throws -> TariffV1Response?

    func fetchDetailedTariffs() async throws -> TariffSettingsV3Response?

    func fetchServerInfo() async throws -> ServerInfo

    func fetchEnergyOverview() async throws -> EnergyOverview

    func fetchStatisticsOverview() async throws -> StatisticsOverview

    func fetchStatistics(from: Date?, to: Date, accuracy: Accuracy) async throws -> Statistics?

    func setCarChargingMode(
        sensorId: String, carCharging: ControlCarChargingRequest
    ) async throws -> Bool
    
    func setSensorPriority(
        sensorId: String, priority: Int
    ) async throws -> Bool
    
    func setBatteryMode(
        sensorId: String,
        batteryModeInfo: BatteryModeInfo
    ) async throws -> Bool
}

extension EnergyManager {
    func fetchMainData(from: Date, to: Date, interval: Int = 300) async throws -> MainData {
        return try await self.fetchMainData(from: from, to: to, interval: interval)
    }
}
