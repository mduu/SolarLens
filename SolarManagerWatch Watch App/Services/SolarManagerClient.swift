//
//  SolarManagerClient.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 29.09.2024.
//

import Foundation
import Combine

class SolarManagerClient {
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
