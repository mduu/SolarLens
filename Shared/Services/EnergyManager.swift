import Combine
import Foundation

protocol EnergyManager {
    func login(username: String, password: String) async -> Bool

    func fetchOverviewData(lastOverviewData: OverviewData?) async throws
        -> OverviewData
    
    func fetchChargingData() async throws -> CharingInfoData
    
    func fetchSolarDetails() async throws -> SolarDetailsData
    
    func fetchConsumptions(from: Date, to: Date) async throws -> ConsumptionData
    
    func fetchTodaysBatteryHistory() async throws -> [BatteryHistory]
    
    func fetchServerInfo() async throws -> ServerInfo

    func fetchEnergyOverview() async throws -> EnergyOverview

    func fetchStatisticsOverview() async throws -> StatisticsOverview

    func fetchStatistics(from: Date, to: Date, accuracy: Accuracy) async throws -> Statistics

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
