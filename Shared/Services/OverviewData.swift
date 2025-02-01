import SwiftUI

@Observable
class OverviewData {
    private let minGridConsumptionTreashold: Int = 100
    private let minGridIngestionTreashold: Int = 100

    var currentSolarProduction: Int = 0
    var currentOverallConsumption: Int = 0
    var currentBatteryLevel: Int? = 0
    var currentBatteryChargeRate: Int? = 0
    var currentSolarToGrid: Int = 0
    var currentGridToHouse: Int = 0
    var currentSolarToHouse: Int = 0
    var solarProductionMax: Double = 0
    var hasConnectionError: Bool = false
    var lastUpdated: Date? = nil
    var lastSuccessServerFetch: Date? = nil
    var isAnyCarCharing: Bool = false
    var chargingStations: [ChargingStation] = []
    var isStaleData: Bool = false
    var hasAnyCarChargingStation: Bool = true
    var todaySelfConsumption: Double? = nil
    var todaySelfConsumptionRate: Double? = nil
    var todayProduction: Double? = nil
    var todayConsumption: Double? = nil

    static func empty() -> OverviewData {
        OverviewData(
            currentSolarProduction: 0,
            currentOverallConsumption: 0,
            currentBatteryLevel: nil,
            currentBatteryChargeRate: nil,
            currentSolarToGrid: 0,
            currentGridToHouse: 0,
            currentSolarToHouse: 0,
            solarProductionMax: 0,
            hasConnectionError: true,
            lastUpdated: Date(),
            lastSuccessServerFetch: Date(),
            isAnyCarCharing: false,
            chargingStations: [],
            todaySelfConsumption: nil,
            todaySelfConsumptionRate: nil,
            todayProduction: nil,
            todayConsumption: nil
        )
    }

    static func fake() -> OverviewData {
        .init(
            currentSolarProduction: 4550,
            currentOverallConsumption: 1200,
            currentBatteryLevel: 78,
            currentBatteryChargeRate: 3400,
            currentSolarToGrid: 10,
            currentGridToHouse: 0,
            currentSolarToHouse: 1200,
            solarProductionMax: 11000,
            hasConnectionError: false,
            lastUpdated: Date(),
            lastSuccessServerFetch: Date(),
            isAnyCarCharing: true,
            chargingStations: [
                .init(
                    id: "42",
                    name: "Keba 1",
                    chargingMode: ChargingMode.withSolarPower,
                    priority: 0,
                    currentPower: 0,
                    signal: SensorConnectionStatus.connected),
                .init(
                    id: "43",
                    name: "Keba 2",
                    chargingMode: ChargingMode.withSolarPower,
                    priority: 1,
                    currentPower: 11356,
                    signal: SensorConnectionStatus.connected),
                .init(
                    id: "44",
                    name: "Keba 3",
                    chargingMode: ChargingMode.withSolarPower,
                    priority: 2,
                    currentPower: 0,
                    signal: SensorConnectionStatus.connected),
            ]
        )
    }

    init() {
    }

    init(
        currentSolarProduction: Int,
        currentOverallConsumption: Int,
        currentBatteryLevel: Int?,
        currentBatteryChargeRate: Int?,
        currentSolarToGrid: Int,
        currentGridToHouse: Int,
        currentSolarToHouse: Int,
        solarProductionMax: Double,
        hasConnectionError: Bool,
        lastUpdated: Date?,
        lastSuccessServerFetch: Date?,
        isAnyCarCharing: Bool,
        chargingStations: [ChargingStation],
        todaySelfConsumption: Double? = nil,
        todaySelfConsumptionRate: Double? = nil,
        todayProduction: Double? = nil,
        todayConsumption: Double? = nil
    ) {
        self.currentSolarProduction = currentSolarProduction
        self.currentOverallConsumption = currentOverallConsumption
        self.currentBatteryLevel = currentBatteryLevel
        self.currentBatteryChargeRate = currentBatteryChargeRate
        self.currentSolarToGrid = currentSolarToGrid
        self.currentGridToHouse = currentGridToHouse
        self.currentSolarToHouse = currentSolarToHouse
        self.solarProductionMax = solarProductionMax
        self.hasConnectionError = hasConnectionError
        self.lastUpdated = lastUpdated
        self.lastSuccessServerFetch = lastSuccessServerFetch
        self.isAnyCarCharing = isAnyCarCharing
        self.chargingStations = chargingStations
        self.isStaleData = getIsStaleData()
        self.hasAnyCarChargingStation = chargingStations.count > 0
        self.todaySelfConsumption = todaySelfConsumption
        self.todaySelfConsumptionRate = todaySelfConsumptionRate
        self.todayProduction = todayProduction
        self.todayConsumption = todayConsumption
    }

    func isFlowBatteryToHome() -> Bool {
        return currentBatteryChargeRate ?? 0 <= -100
    }

    func isFlowSolarToBattery() -> Bool {
        return currentBatteryChargeRate ?? 0 >= 100
    }

    func isFlowSolarToHouse() -> Bool {
        return currentSolarToHouse >= 100
    }

    func isFlowSolarToGrid() -> Bool {
        return currentSolarToGrid >= minGridIngestionTreashold
    }

    func isFlowGridToHouse() -> Bool {
        return currentGridToHouse >= minGridConsumptionTreashold
    }

    /**
     Return <code>true</code> if the fetched server-data is outdated.
     This indicates a server-side issue in Solar Manager backend.
     */
    private func getIsStaleData() -> Bool {
        guard let lastFetch = lastSuccessServerFetch,
            let lastUpdate = lastUpdated
        else {
            if lastSuccessServerFetch == nil {
                return false
            }

            if lastUpdated == nil {
                return true
            }

            return false
        }

        return lastFetch.timeIntervalSince(lastUpdate) > 30 * 60
    }
}

@Observable
class ChargingStation: Identifiable {
    var id: String
    var name: String
    var chargingMode: ChargingMode
    var priority: Int  // lower number is higher Priority (ordering)
    var currentPower: Int  // Watt
    var signal: SensorConnectionStatus?

    init(
        id: String, name: String, chargingMode: ChargingMode, priority: Int,
        currentPower: Int, signal: SensorConnectionStatus? = nil
    ) {
        self.id = id
        self.name = name
        self.chargingMode = chargingMode
        self.priority = priority
        self.currentPower = currentPower
        self.signal = signal
    }
}
