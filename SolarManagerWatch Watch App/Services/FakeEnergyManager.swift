//
//  FakeEnergyManager.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 06.10.2024.
//


import Foundation
import Combine

class FakeEnergyManager : EnergyManager {
    let data: OverviewData
    
    init(data: OverviewData? = nil) {
        self.data = data ?? OverviewData(
                currentSolarProduction: 3200,
                currentOverallConsumption: 800,
                currentBatteryLevel: 42,
                currentBatteryChargeRate: 2400,
                currentSolarToGrid: 120, currentGridToHouse: 100,
                currentSolarToHouse: 1100,
                hasConnectionError: true)
    }
    
    func fetchOverviewData(lastOverviewData: OverviewData?) -> OverviewData {
        return data
    }
}
