import Combine
import Foundation

class FakeEnergyManager: EnergyManager {
    func fetchServerInfo() async throws -> ServerInfo {
        ServerInfo.fake()
    }

    private static var _instance: FakeEnergyManager? = nil
    static func instance() -> any EnergyManager {
        if _instance == nil {
            _instance = FakeEnergyManager()
        }
        return _instance!
    }
    
    let data: OverviewData
    
    

    func login(username: String, password: String) async -> Bool {
        return true
    }

    init(data: OverviewData? = nil) {
        self.data =
            data
            ?? OverviewData(
                currentSolarProduction: 3200,
                currentOverallConsumption: 800,
                currentBatteryLevel: 42,
                currentBatteryChargeRate: 2400,
                currentSolarToGrid: 120, currentGridToHouse: 100,
                currentSolarToHouse: 1100,
                solarProductionMax: 11000,
                hasConnectionError: true,
                lastUpdated: Date(),
                lastSuccessServerFetch: Date(),
                isAnyCarCharing: false,
                chargingStations: [],
                devices: [])
    }

    func fetchOverviewData(lastOverviewData: OverviewData?) -> OverviewData {
        return data
    }
    
    func fetchChargingData() async throws -> CharingInfoData {
        return CharingInfoData(
            totalCharedToday: 32400,
            currentCharging: 6540)
    }
    
    func fetchSolarDetails() async throws -> SolarDetailsData {
        return SolarDetailsData.init(
            todaySolarProduction: 34321,
            forecastToday: ForecastItem(min: 2.1, max: 8.7, expected: 6.4),
            forecastTomorrow: ForecastItem(min: 4.3, max: 10.1, expected: 8.3),
            forecastDayAfterTomorrow: ForecastItem(min: 1.2, max: 4.3, expected: 3.5))
    }
    
    func fetchConsumptions(from: Date, to: Date) async throws -> ConsumptionData {
        return ConsumptionData.fake()
    }

    func setCarChargingMode(
        sensorId: String, carCharging: ControlCarChargingRequest
    ) async throws -> Bool {
        print("setCarChargingMode: \(carCharging)")
        return true
    }
    
    func setSensorPriority(sensorId: String, priority: Int) async throws -> Bool {
        print("setSensorPriority: Sensor=\(sensorId), New Prio=\(priority)")
        return true
    }

}
