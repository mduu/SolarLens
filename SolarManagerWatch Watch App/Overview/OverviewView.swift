//
//  OverviewView.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 29.09.2024.
//

import SwiftUI

struct OverviewView: View {
    @EnvironmentObject var model: BuildingStateViewModel

    var body: some View {
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
                                .currentGridToHouse
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
                                .currentOverallConsumption
                        )
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, 0)
                .padding(.leading, 10)
                .padding(.trailing, 10)

                HStack {
                    Text(
                        model.lastUpdatedAt?.formatted(date: .numeric, time: .standard) ?? "-"
                    )
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                }.padding(.top, 2)
            }
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in
                    Task {
                        await model.fetchServerData()
                    }
                }
            }
        }
    }
}

#Preview("English") {
    OverviewView()
        .environmentObject(
            BuildingStateViewModel(
                energyManagerClient: FakeEnergyManager()
            ))
}

#Preview("German") {
    OverviewView()
        .environmentObject(
            BuildingStateViewModel(
                energyManagerClient: FakeEnergyManager()
            )
        )
        .environment(\.locale, Locale(identifier: "DE"))
}
