//
//  OverviewView.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 29.09.2024.
//

import SwiftUI

struct OverviewView: View {
    @EnvironmentObject var model: BuildingStateViewModel
    
    @State private var refreshTimer: Timer?

    var body: some View {
        VStack {
            ZStack {
                VStack {
                    HStack {
                        if model.overviewData.hasConnectionError {
                            Image(systemName: "exclamationmark.icloud")
                                .foregroundColor(Color.red)
                                .symbolEffect(
                                    .pulse.wholeSymbol,
                                    options: .repeat(.continuous))
                        }

                        if model.error != nil {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(Color.yellow)
                                .symbolEffect(
                                    .breathe.wholeSymbol)
                        }
                    }

                    Spacer()
                }

                VStack {
                    Grid {
                        GridRow(alignment: .center) {
                            SolarProductionView(
                                currentSolarProduction: $model.overviewData
                                    .currentSolarProduction,
                                maximumSolarProduction: $model.overviewData
                                    .solarProductionMax
                            )

                            if model.overviewData.isFlowSolarToGrid() {
                                Image(systemName: "arrow.right")
                                    .foregroundColor(.orange)
                                    .symbolEffect(
                                        .wiggle.byLayer,
                                        options: .repeat(.periodic(delay: 0.7)))
                            } else {
                                Text("")
                            }

                            NetworkConsumptionView(
                                currentNetworkConsumption: $model.overviewData
                                    .currentGridToHouse,
                                currentNetworkFeedin: $model.overviewData
                                    .currentSolarToGrid,
                                isFlowFromNetwork: model.overviewData
                                    .isFlowGridToHouse(),
                                isFlowToNetwork: model.overviewData
                                    .isFlowSolarToGrid()
                            )
                        }

                        GridRow(alignment: .center) {
                            if model.overviewData.isFlowSolarToBattery() {
                                Image(systemName: "arrow.down")
                                    .foregroundColor(.green)
                                    .symbolEffect(
                                        .wiggle.byLayer,
                                        options: .repeat(.periodic(delay: 0.7)))
                            } else {
                                Text("")
                            }

                            if model.overviewData.isFlowSolarToHouse() {
                                Image(systemName: "arrow.down.right")
                                    .foregroundColor(.green)
                                    .symbolEffect(
                                        .wiggle.byLayer,
                                        options: .repeat(.periodic(delay: 0.7)))
                            } else {
                                Text("")
                            }

                            if model.overviewData.isFlowGridToHouse() {
                                Image(systemName: "arrow.down")
                                    .foregroundColor(.orange)
                                    .symbolEffect(
                                        .wiggle.byLayer,
                                        options: .repeat(.periodic(delay: 0.7)))
                            } else {
                                Text("")
                            }
                        }.frame(minWidth: 30, minHeight: 20)

                        GridRow(alignment: .center) {

                            BatteryView(
                                currentBatteryLevel: $model.overviewData
                                    .currentBatteryLevel,
                                currentChargeRate: $model.overviewData
                                    .currentBatteryChargeRate
                            )

                            if model.overviewData.isFlowBatteryToHome() {
                                Image(systemName: "arrow.right")
                                    .foregroundColor(.green)
                                    .symbolEffect(
                                        .wiggle.byLayer,
                                        options: .repeat(.periodic(delay: 0.7)))
                            } else {
                                Text("")
                            }

                            HouseholdConsumptionView(
                                currentOverallConsumption: $model.overviewData
                                    .currentOverallConsumption,
                                isAnyCarCharging: $model.overviewData
                                    .isAnyCarCharing
                            )
                        }
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 0)
                    .padding(.leading, 10)
                    .padding(.trailing, 10)

                    HStack {
                        Text(
                            model.overviewData.lastUpdated?.formatted(
                                date: .numeric, time: .standard) ?? "-"
                        )
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    }.padding(.top, 2)
                }
                .onAppear {
                    Task {
                        await model.fetchServerData()
                    }
                    if refreshTimer == nil {
                        refreshTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) {
                            _ in
                            Task {
                                await model.fetchServerData()
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview("English") {
    OverviewView()
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

#Preview("German") {
    OverviewView()
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
        .environment(\.locale, Locale(identifier: "DE"))
}
