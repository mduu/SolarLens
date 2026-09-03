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

    /// Aggregate per-period consumption across all heat-pump sensors.
    /// Used by the iOS Statistics tab. Returns 0 when no heat pumps are
    /// configured.
    func fetchHeatpumpTotal(period: Period) async throws -> Double

    /// Aggregate per-period consumption across all boiler / water-heater
    /// sensors. Used by the iOS Statistics tab. Returns 0 when none are
    /// configured.
    func fetchBoilerTotal(period: Period) async throws -> Double

    /// Consumption of every car charging station over an arbitrary range.
    ///
    /// The `period:` variants above are pinned to "day / week / month ending
    /// now" by the Solar Manager API, which is useless once the iOS charts let
    /// the user scroll back in time. These derive the same figure from the
    /// per-device data endpoint, which does take a range. Returns `nil` when
    /// the range is too long to sample at a sensible resolution.
    func fetchCarChargingTotal(from: Date, to: Date) async throws -> Double?

    /// Heat-pump consumption over an arbitrary range. See
    /// `fetchCarChargingTotal(from:to:)`.
    func fetchHeatpumpTotal(from: Date, to: Date) async throws -> Double?

    /// Boiler / water-heater consumption over an arbitrary range. See
    /// `fetchCarChargingTotal(from:to:)`.
    func fetchBoilerTotal(from: Date, to: Date) async throws -> Double?

    func fetchSolarDetails() async throws -> SolarDetailsData

    func fetchMainData(from: Date, to: Date, interval: Int) async throws -> MainData

    /// Per-battery power history over an arbitrary range.
    func fetchBatteryHistory(from: Date, to: Date) async throws -> [BatteryHistory]

    func fetchTodaysBatteryHistory() async throws -> [BatteryHistory]

    func fetchTariff() async throws -> TariffV1Response?

    func fetchDetailedTariffs() async throws -> TariffSettingsV3Response?

    /// Dynamic / spot tariff time-series (e.g. for users on a dynamic import
    /// tariff). Returns nil when the user has no dynamic tariff.
    func fetchDynamicTariff() async throws -> DynamicTariffResponse?

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
    /// Default-argument shim for the `interval:` requirement. Every conformer
    /// must implement `fetchMainData(from:to:interval:)` itself — this
    /// overload would otherwise become its own witness and recurse forever.
    func fetchMainData(from: Date, to: Date, interval: Int = 300) async throws -> MainData {
        return try await self.fetchMainData(from: from, to: to, interval: interval)
    }

    func fetchDynamicTariff() async throws -> DynamicTariffResponse? {
        return nil
    }

    func fetchTodaysBatteryHistory() async throws -> [BatteryHistory] {
        try await fetchBatteryHistory(
            from: Date.todayStartOfDay(),
            to: Date.todayEndOfDay()
        )
    }
}
