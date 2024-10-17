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
    @State private var networkProductionMaxValue = 20_000

    var body: some View {
        VStack {
            // Background Gradient
            LinearGradient(
                gradient: getBackgroundGRadient(),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

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
                        currentNetworkConsumption: $model.overviewData
                            .currentGridToHouse,
                        maximumNetworkConsumption:
                            $networkProductionMaxValue
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
                            .foregroundColor(.red)
                            .symbolEffect(
                                .wiggle.byLayer,
                                options: .repeat(.periodic(delay: 0.7)))
                    } else {
                        Text("")
                    }
                }.frame(width: 30, height: 20)

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
                        consumptionMaxValue: $networkProductionMaxValue
                    )
                }
            }
            .padding(.leading, 20)
            .padding(.trailing, 20)

            HStack {
                Text(
                    model.lastUpdatedAt?.formatted() ?? "-"
                )
                .font(.system(size: 12))
                .foregroundColor(.gray)
            }.padding(.top, 10)
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

    private func getBackgroundGRadient() -> Gradient {
        if solarPercentage() >= 40 {
            return Gradient(colors: [.yellow, .black])
        }

        if solarPercentage() >= 10 {
            return Gradient(colors: [.yellow.opacity(0.7), .black])
        }

        if solarPercentage() >= 1 {
            return Gradient(colors: [.red, .black])
        }

        return Gradient(colors: [.blue.opacity(0.5), .black])
    }
}

#Preview {
    OverviewView()
        .environmentObject(
            BuildingStateViewModel(
                energyManagerClient: FakeEnergyManager()
            ))
}
