//
//  FakeEnergyManager.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 06.10.2024.
//


import Foundation
import Combine

class FakeEnergyManager : EnergyManagerClient {
    let data: OverviewData
    
    init(data: OverviewData? = nil) {
        self.data = data ?? OverviewData(
                currentSolarProduction: 3200,
                currentOverallConsumption: 800,
                currentBatteryLevel: 42,
                currentNetworkConsumption: 100,
                currentBatteryChargeRate: 2400)
    }
    
    func fetchOverviewData() -> OverviewData {
        return data
    }
}
