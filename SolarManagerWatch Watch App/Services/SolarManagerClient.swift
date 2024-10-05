//
//  SolarManagerClient.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 29.09.2024.
//

import Foundation
import Combine

protocol EnergyManagerClient {
    func fetchOverviewData() -> OverviewData
}

class SolarManagerClient : EnergyManagerClient {
    func fetchOverviewData() -> OverviewData
    {
        return OverviewData(
            currentSolarProduction: 3.2,
            currentOverallConsumption: 0.8,
            currentBatteryLevel: 42,
            currentNetworkConsumption: 0.01,
            currentBatteryChargeRate: 2.4)
    }
}

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
