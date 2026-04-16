import Combine
internal import Foundation

class FakeEnergyManager: EnergyManager {

    func fetchStatisticsOverview() async throws -> StatisticsOverview {
        StatisticsOverview(
            week: Statistics(
                consumption: 1234.22,
                production: 987.21,
                selfConsumption: 801.99,
                selfConsumptionRate: 100 / 987.21 * 801.99,
                autarchyDegree: 100 / 1234.22 * 987.21
            ),
            month: Statistics(
                consumption: 1234.22,
                production: 987.21,
                selfConsumption: 801.99,
                selfConsumptionRate: 100 / 987.21 * 801.99,
                autarchyDegree: 100 / 1234.22 * 987.21
            ),
            year: Statistics(
                consumption: 1234.22,
                production: 987.21,
                selfConsumption: 801.99,
                selfConsumptionRate: 100 / 987.21 * 801.99,
                autarchyDegree: 100 / 1234.22 * 987.21
            ),
            overall: Statistics(
                consumption: 1234.22,
                production: 987.21,
                selfConsumption: 801.99,
                selfConsumptionRate: 100 / 987.21 * 801.99,
                autarchyDegree: 100 / 1234.22 * 987.21
            )
        )
    }

    func fetchStatistics(from: Date?, to: Date, accuracy: Accuracy) async throws -> Statistics? {
        Statistics(
            consumption: 1234.22,
            production: 987.21,
            selfConsumption: 801.99,
            selfConsumptionRate: 100 / 987.21 * 801.99,
            autarchyDegree: 100 / 1234.22 * 987.21
        )
    }

    func fetchEnergyOverview() async throws -> EnergyOverview {
        return EnergyOverview()
    }

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
                currentSolarToGrid: 120,
                currentGridToHouse: 100,
                currentSolarToHouse: 1100,
                solarProductionMax: 11000,
                hasConnectionError: true,
                lastUpdated: Date(),
                lastSuccessServerFetch: Date(),
                isAnyCarCharing: false,
                chargingStations: [],
                devices: []
            )
    }

    func fetchOverviewData(lastOverviewData: OverviewData?) -> OverviewData {
        return data
    }

    func fetchTodayStatistics() async throws -> TodayStatistics? {
        return TodayStatistics(
            selfConsumption: data.todaySelfConsumption,
            selfConsumptionRate: data.todaySelfConsumptionRate,
            autarchyDegree: data.todayAutarchyDegree,
            production: data.todayProduction,
            consumption: data.todayConsumption
        )
    }

    func fetchCarChargingTotal(period: Period) async throws -> Double {
        return 32400
    }

    func fetchChargingData() async throws -> CharingInfoData {
        return CharingInfoData(
            totalCharedToday: 32400,
            currentCharging: 6540
        )
    }

    func fetchSolarDetails() async throws -> SolarDetailsData {
        return SolarDetailsData.init(
            todaySolarProduction: 34321,
            forecastToday: ForecastItem(min: 2.1, max: 8.7, expected: 6.4),
            forecastTomorrow: ForecastItem(min: 4.3, max: 10.1, expected: 8.3),
            forecastDayAfterTomorrow: ForecastItem(
                min: 1.2,
                max: 4.3,
                expected: 3.5
            )
        )
    }

    func fetchTodaysBatteryHistory() async throws -> [BatteryHistory] {
        return BatteryHistory.fakeHistory()
    }

    func fetchTariff() async throws -> TariffV1Response? {
        return TariffV1Response(
            highTariff: 28,
            tariffType: "double"
        )
    }

    func fetchDetailedTariffs() async throws -> TariffSettingsV3Response? {
        return TariffSettingsV3Response(
            purchase: TariffConfig(
                tariffType: "variable",
                variableTariff: VariableTariffConfig(
                    prices: TariffPrices(lowTariff: 18, highTariff: 28),
                    commonSeason: TariffSeason(
                        mondayFriday: [
                            TariffTimeSlot(fromTime: "00:00", tariffOption: "lowTariff"),
                            TariffTimeSlot(fromTime: "06:00", tariffOption: "highTariff"),
                            TariffTimeSlot(fromTime: "21:00", tariffOption: "lowTariff"),
                        ],
                        saturday: [
                            TariffTimeSlot(fromTime: "00:00", tariffOption: "lowTariff"),
                        ],
                        sunday: [
                            TariffTimeSlot(fromTime: "00:00", tariffOption: "lowTariff"),
                        ]
                    )
                )
            ),
            feedIn: TariffConfig(
                tariffType: "single",
                singleTariff: SingleTariffConfig(price: 8.5)
            )
        )
    }

    func fetchMainData(from: Date, to: Date) async throws -> MainData
    {
        return MainData.fake()
    }

    func setCarChargingMode(
        sensorId: String,
        carCharging: ControlCarChargingRequest
    ) async throws -> Bool {
        print("setCarChargingMode: \(carCharging)")
        return true
    }

    func setSensorPriority(sensorId: String, priority: Int) async throws -> Bool
    {
        print("setSensorPriority: Sensor=\(sensorId), New Prio=\(priority)")
        return true
    }
    
    func setBatteryMode(
        sensorId: String,
        batteryModeInfo: BatteryModeInfo
    ) async throws -> Bool {
        print(
            "setBatteryMode: Sensor=\(sensorId), New Mode=\(batteryModeInfo.batteryChargingMode)"
        )
        
        return true
    }

}
