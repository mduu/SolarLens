//
//  ChargingControlView.swift
//  SolarManagerWatch Watch App
//
//  Created by Marc Dürst on 25.10.2024.
//

import SwiftUI

struct ChargingControlView: View {
    @EnvironmentObject var model: BuildingStateViewModel

    var body: some View {
        ScrollView {
            Text("Car Charging")
                .font(.headline)
            
                ForEach(model.overviewData.sensors ?? [], id: \._id) {sensor in
                }
        }
    }
}

#Preview {
    ChargingControlView()
        .environmentObject(
            BuildingStateViewModel.fake(
                overviewData: .init(
                    currentSolarProduction: 4550,
                    currentOverallConsumption: 1200,
                    currentBatteryLevel: 78,
                    currentBatteryChargeRate: 3400,
                    currentSolarToGrid: 10,
                    currentGridToHouse: 0,
                    currentSolarToHouse: 1200,
                    solarProductionMax: 11000,
                    hasConnectionError: false,
                    lastUpdated: Date(),
                    isAnyCarCharing: false,
                    sensors: nil
                )
            ))
}
