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
    var devices: [Device] = []
    var isStaleData: Bool = false
    var hasAnyCarChargingStation: Bool = true
    var hasAnyBattery: Bool = true
    var todaySelfConsumption: Double? = nil
    var todaySelfConsumptionRate: Double? = nil
    var todayAutarchyDegree: Double? = nil
    var todayProduction: Double? = nil
    var todayConsumption: Double? = nil
    var todayGridImported: Double? = nil
    var todayGridExported: Double? = nil
    var todayBatteryCharged: Double? = nil
    var cars: [Car] = []

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
        devices: [Device],
        todaySelfConsumption: Double? = nil,
        todaySelfConsumptionRate: Double? = nil,
        todayAutarchyDegree: Double? = nil,
        todayProduction: Double? = nil,
        todayConsumption: Double? = nil,
        todayGridImported: Double? = nil,
        todayGridExported: Double? = nil,
        todayBatteryCharged: Double? = nil,
        cars: [Car] = []
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
        self.devices = devices
        self.isStaleData = getIsStaleData()
        self.hasAnyCarChargingStation = chargingStations.count > 0
        self.hasAnyBattery = devices
            .first(where: { $0.deviceType == .battery }) != nil
        self.todaySelfConsumption = todaySelfConsumption
        self.todaySelfConsumptionRate = todaySelfConsumptionRate
        self.todayAutarchyDegree = todayAutarchyDegree
        self.todayProduction = todayProduction
        self.todayConsumption = todayConsumption
        self.todayGridImported = todayGridImported
        self.todayGridExported = todayGridExported
        self.todayBatteryCharged = todayBatteryCharged
        self.cars = cars
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

    func getBatteryForecast() -> BatteryForecast? {
        guard let currentOverallPercent = currentBatteryLevel else {
            return nil
        }

        let batteries = devices.filter { $0.deviceType == .battery }

        let totalBatteryCapacity: Double =
            batteries
            .reduce(0) { (currentSum, battery) in
                if let capa = battery.batteryInfo?.batteryCapacityKwh {
                    return currentSum + capa
                } else {
                    return currentSum
                }
            }

        let currentBatteryCapacityKwh: Double =
            Double(totalBatteryCapacity) / 100.0 * Double(currentOverallPercent)
        let isDischarging = currentBatteryChargeRate ?? 0 < -50 && currentOverallPercent > 0
        let isCharging = currentBatteryChargeRate ?? 0 > 50 && currentOverallPercent < 100

        // Discharging
        var durationUntilEmpty: TimeInterval? = nil
        if isDischarging {
            let minimumCapacityKwh: Double = totalBatteryCapacity * 0.05
            let remainingCapacityKwh = currentBatteryCapacityKwh - minimumCapacityKwh
            let dishargingRateKw = Double(currentBatteryChargeRate! * -1) / 1000
            let hours = remainingCapacityKwh / dishargingRateKw
            durationUntilEmpty = TimeInterval(hours * 3600)
        }

        // Charging
        var durationUntilFull: TimeInterval? = nil
        if isCharging {
            let capacityToChargeKwh = totalBatteryCapacity - currentBatteryCapacityKwh
            let chargingRateKw = Double(currentBatteryChargeRate ?? 0) / 1000
            let hours = capacityToChargeKwh / chargingRateKw
            durationUntilFull = TimeInterval(hours * 3600)
        }

        return BatteryForecast(
            durationUntilFullyCharged: durationUntilFull,
            timeWhenFullyCharged: durationUntilFull != nil
                ? Date().addingTimeInterval(durationUntilFull!)
                : nil,
            durationUntilDischarged: durationUntilEmpty,
            timeWhenDischarged: durationUntilEmpty != nil
                ? Date().addingTimeInterval(durationUntilEmpty!)
                : nil
        )
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
