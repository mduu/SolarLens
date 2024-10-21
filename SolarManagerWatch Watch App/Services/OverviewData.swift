//
//  OverviewData.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 05.10.2024.
//

import Foundation

struct OverviewData {
    private let minGridConsumptionTreashold: Int = 30
    private let minGridIngestionTreashold: Int = 10
    
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
    
    func isFlowBatteryToHome() -> Bool {
        return currentBatteryChargeRate ?? 0 < 0
    }
    
    func isFlowSolarToBattery() -> Bool {
        return currentBatteryChargeRate ?? 0 > 0
    }
    
    func isFlowSolarToHouse() -> Bool {
        return currentSolarToHouse > 0
    }
    
    func isFlowSolarToGrid() -> Bool {
        return currentSolarToGrid > minGridIngestionTreashold
    }
    
    func isFlowGridToHouse() -> Bool {
        return currentGridToHouse > minGridConsumptionTreashold
    }
}
