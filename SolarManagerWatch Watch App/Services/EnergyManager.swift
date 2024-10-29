//
//  EnergyManagerClient.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 06.10.2024.
//

import Combine
import Foundation

protocol EnergyManager {
    func login(username: String, password: String) async -> Bool
    func fetchOverviewData(lastOverviewData: OverviewData?) async throws -> OverviewData
    func setCarChargingMode(carCharging: ControlCarChargingRequest) async throws -> Bool
}
