//
//  OverviewData.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 05.10.2024.
//

public struct OverviewData: Codable {
    var currentSolarProduction: Int = 0
    var currentOverallConsumption: Int = 0
    var currentBatteryLevel: Int? = 0
    var currentNetworkConsumption: Int = 0
    var currentBatteryChargeRate: Int? = 0
}
