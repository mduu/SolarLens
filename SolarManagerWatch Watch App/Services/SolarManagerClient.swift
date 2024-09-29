//
//  SolarManagerClient.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 29.09.2024.
//

class SolarManagerClient {
    public private(set) var currentBuildingState: BuildingStateModel = .init()
    
    init() {
        self.update()
    }
    
    func update() {
        // TODO Replace fake implementation
        currentBuildingState.updateOverview(
            currentSolarProduction: 3.2,
            currentOverallConsumption: 0.8,
            currentBatteryLevel: 42,
            currentNetworkConsumption: 0.01,
            currentBatteryChargeRate: 2.4
        )
    }
}
