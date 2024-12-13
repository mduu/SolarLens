import Combine
import Foundation

protocol EnergyManager {
    func login(username: String, password: String) async -> Bool

    func fetchOverviewData(lastOverviewData: OverviewData?) async throws
        -> OverviewData
    
    func fetchChargingData() async throws -> CharingInfoData
    
    func fetchSolarDetails() async throws -> SolarDetailsData

    func setCarChargingMode(
        sensorId: String, carCharging: ControlCarChargingRequest
    ) async throws -> Bool
}
