//
//  ChargingOptionsPopupView.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 02.11.2024.
//

import SwiftUI

struct ChargingOptionsPopupView: View {
    @EnvironmentObject var model: BuildingStateViewModel
    @Binding var chargingMode: ChargingMode
    @Binding var chargingStation: ChargingStation
    
    @Environment(\.dismiss) var dismiss
    
    @State var constantCurrent: Int = 6
    private let minConstantCurrent: Int = 6
    private let maxConstantCurrent: Int = 32

    var body: some View {

        switch chargingMode {
        case .constantCurrent: constantCurrentView
        default:
            Text("Unknown charging mode")
                .foregroundColor(.red)
        }
    }
    
    var constantCurrentView: some View {
        ZStack {
            VStack {
                HStack {
                    
                    Button(action: {
                        constantCurrent -= 1
                        if constantCurrent < minConstantCurrent {
                            constantCurrent = minConstantCurrent
                        }
                    }) {
                        Image(systemName: "minus")
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.accent)
                    .padding()
                    
                    Text("\(constantCurrent) A")
                    
                    Button(action: {
                        constantCurrent += 1
                        if constantCurrent > maxConstantCurrent {
                            constantCurrent = maxConstantCurrent
                        }
                    }) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.accent)
                    .padding()
                }
                
                Button(action: {
                    Task {
                        await model.setCarCharging(
                            sensorId: chargingStation.id,
                            newCarCharging: .init(constantCurrent: constantCurrent))
                        dismiss()
                    }
                }) {
                    Text("Set")
                }
                .buttonStyle(.bordered)
                .foregroundColor(.green)
                .padding()
            }
            
            if model.isChangingCarCharger {
                HStack {
                    ProgressView()
                }.background(Color.black.opacity(0.8))
            }
        }
    }

}

#Preview("Constant Current") {
    ChargingOptionsPopupView(
        chargingMode: .constant(.constantCurrent),
        chargingStation: .constant(
            ChargingStation.init(
                id: "id-1",
                name: "Station #1",
                chargingMode: .withSolarPower,
                priority: 1,
                currentPower: 0,
                signal: .connected)))
    .environmentObject(
        BuildingStateViewModel.fake(
            overviewData: .init(
                    currentSolarProduction: 4500,
                    currentOverallConsumption: 400,
                    currentBatteryLevel: 99,
                    currentBatteryChargeRate: 150,
                    currentSolarToGrid: 3600,
                    currentGridToHouse: 0,
                    currentSolarToHouse: 400,
                    solarProductionMax: 11000,
                    hasConnectionError: false,
                    lastUpdated: Date(),
                    isAnyCarCharing: true,
                    chargingStations: []
                )
        )
    )
}
