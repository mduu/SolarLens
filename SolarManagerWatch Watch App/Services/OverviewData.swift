//
//  OverviewData.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 05.10.2024.
//

public struct OverviewData: Codable {
    var currentSolarProduction: Double = 0
    var currentOverallConsumption: Double = 0
    var currentBatteryLevel: Double = 0
    var currentNetworkConsumption: Double = 0
    var currentBatteryChargeRate: Double = 0
}
