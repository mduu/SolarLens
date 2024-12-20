//
//  OverviewData.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 05.10.2024.
//

import Foundation

class OverviewData: ObservableObject {
    private let minGridConsumptionTreashold: Int = 100
    private let minGridIngestionTreashold: Int = 100

    @Published var currentSolarProduction: Int = 0
    @Published var currentOverallConsumption: Int = 0
    @Published var currentBatteryLevel: Int? = 0
    @Published var currentBatteryChargeRate: Int? = 0
    @Published var currentSolarToGrid: Int = 0
    @Published var currentGridToHouse: Int = 0
    @Published var currentSolarToHouse: Int = 0
    @Published var solarProductionMax: Double = 0
    @Published var hasConnectionError: Bool = false
    @Published var lastUpdated: Date? = nil
    @Published var lastSuccessServerFetch: Date? = nil
    @Published var isAnyCarCharing: Bool = false
    @Published var chargingStations: [ChargingStation] = []
    @Published var isStaleData: Bool = false
    @Published var hasAnyCarChargingStation: Bool = true

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
        chargingStations: [ChargingStation]
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
        guard let lastFetch = lastSuccessServerFetch, let lastUpdate = lastUpdated else {
            if (lastSuccessServerFetch == nil) {
                return false
            }
            
            if (lastUpdated == nil) {
                return true
            }
            
            return false
        }

        return lastFetch.timeIntervalSince(lastUpdate) > 30 * 60
    }
}

class ChargingStation: Observable {
    @Published var id: String
    @Published var name: String
    @Published var chargingMode: ChargingMode
    @Published var priority: Int  // lower number is higher Priority (ordering)
    @Published var currentPower: Int  // Watt
    @Published var signal: SensorConnectionStatus?

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
