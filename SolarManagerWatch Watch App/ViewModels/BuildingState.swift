//
//  BuildingState.swift
//  SolarManagerWatch Watch App
//
//  Created by Marc Dürst on 29.09.2024.
//

import Foundation

public actor BuildingState: Actor {
    public private(set) var currentSolarProduction: Double = 0
    public private(set) var currentOverallConsumption: Double = 0
    public private(set) var currentBatteryLevel: Double = 0
    public private(set) var currentNetworkConsumption: Double = 0
    public private(set) var currentBatteryChargeRate: Double = 0
    
    public func updateOverview(
        currentSolarProduction: Double,
        currentOverallConsumption: Double,
        currentBatteryLevel: Double,
        currentNetworkConsumption: Double,
        currentBatteryChargeRate: Double
    ) {
        self.currentSolarProduction = currentSolarProduction
        self.currentOverallConsumption = currentOverallConsumption
        self.currentBatteryLevel = currentBatteryLevel
        self.currentNetworkConsumption = currentNetworkConsumption
        self.currentBatteryChargeRate = currentBatteryChargeRate
    }
}
