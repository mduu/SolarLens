//
//  ChargingControlView.swift
//  SolarManagerWatch Watch App
//
//  Created by Marc Dürst on 25.10.2024.
//

import SwiftUI

struct ChargingControlView: View {
    @EnvironmentObject var model: BuildingStateViewModel

    @State var newCarCharging: ControlCarChargingRequest? = nil
    @State var showChargingModeConfig: Bool = false

    var body: some View {
        // NavigationStack {
        ZStack {

            LinearGradient(
                gradient: Gradient(colors: [
                    .green.opacity(0.5), .green.opacity(0.2),
                ]), startPoint: .top, endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach($model.overviewData.chargingStations, id: \.id) {
                        chargingStation in

                        VStack(alignment: .leading, spacing: 3) {
                            ChargingStationModeView(
                                isTheOnlyOne: .constant(
                                    model.overviewData.chargingStations.count
                                        <= 1),
                                chargingStation: chargingStation)
                        }  // :VStack
                    }  // :ForEach

                    HStack {
                        Spacer()

                        Button(action: {
                            showChargingModeConfig = true
                            model.pauseFetching()
                        }) {
                            Image(systemName: "gear")
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.secondary)
                        .padding(.trailing, 15)
                        .sheet(isPresented: $showChargingModeConfig) {
                            ChargingModeConfigurationView()
                                .onDisappear {
                                    model.resumeFetching()
                                }

                        }
                    }  // :HStack
                }  // :VStack

            }  // :ScrollView
            .navigationTitle("Charging")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.automatic)

            if model.isChangingCarCharger {
                HStack {
                    ProgressView()
                }.background(Color.black.opacity(0.8))
            }
        }  // :ZStack

        //}  // :NavigationStack
    }  // :Body
}  // :View

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
                    chargingStations: [
                        .init(
                            id: "42",
                            name: "Keba",
                            chargingMode: ChargingMode.withSolarPower,
                            priority: 1,
                            currentPower: 0,
                            signal: SensorConnectionStatus.connected)
                    ]
                )
            ))
}
