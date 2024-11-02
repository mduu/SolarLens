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
    var isAnyCarCharing: Bool = false
    var chargingStations: [ChargingStation] = []
    
    init() {
    }
    
    init(currentSolarProduction: Int,
         currentOverallConsumption: Int,
         currentBatteryLevel: Int?,
         currentBatteryChargeRate: Int?,
         currentSolarToGrid: Int,
         currentGridToHouse: Int,
         currentSolarToHouse: Int,
         solarProductionMax: Double,
         hasConnectionError: Bool,
         lastUpdated: Date?,
         isAnyCarCharing: Bool,
         chargingStations: [ChargingStation])
    {
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
        self.isAnyCarCharing = isAnyCarCharing
        self.chargingStations = chargingStations
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
}

struct ChargingStation: Codable, Observable {
    var id: String
    var name: String
    var chargingMode: ChargingMode
    var priority: Int // lower number is higher Priority (ordering)
    var currentPower: Int // Watt
    var signal: SensorConnectionStatus?
}
