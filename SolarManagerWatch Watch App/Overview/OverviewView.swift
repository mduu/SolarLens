//
//  OverviewView.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 29.09.2024.
//

import SwiftUI

struct OverviewView: View {
    @EnvironmentObject var model: BuildingStateViewModel

    @State private var solarProductionMaxValue = 11_000

    var body: some View {
        VStack {
            Grid {
                GridRow(alignment: .center) {
                    SolarProductionView(
                        currentSolarProduction: $model.overviewData
                            .currentSolarProduction,
                        maximumSolarProduction: $solarProductionMaxValue
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
                        currentNetworkConsumption: $model.overviewData.currentGridToHouse
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
                    model.lastUpdatedAt?.formatted() ?? "-"
                )
                .font(.system(size: 11))
                .foregroundColor(.gray)
            }.padding(.top, 2)
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { _ in
                Task {
                    await model.fetchServerData()
                }
            }
        }
    }

    private func solarPercentage() -> Int {
        return 100 / solarProductionMaxValue
            * model.overviewData.currentSolarProduction
    }
}

#Preview {
    OverviewView()
        .environmentObject(
            BuildingStateViewModel(
                energyManagerClient: FakeEnergyManager()
            ))
}
