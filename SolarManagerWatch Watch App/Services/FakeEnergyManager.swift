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
                currentSolarProduction: 3.2,
                currentOverallConsumption: 0.8,
                currentBatteryLevel: 42,
                currentNetworkConsumption: 0.1,
                currentBatteryChargeRate: 2.4)
    }
    
    func fetchOverviewData() -> OverviewData {
        return data
    }
}
