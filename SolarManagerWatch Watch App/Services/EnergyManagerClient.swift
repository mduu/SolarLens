//
//  EnergyManagerClient.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 06.10.2024.
//


import Combine
import Foundation

protocol EnergyManagerClient {
    func fetchOverviewData() -> OverviewData
}
