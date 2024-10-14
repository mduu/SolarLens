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

            // Other controls on top of background
            VStack {
                VStack(spacing: 20) {
                    HStack(spacing: 50) {
                        SolarProductionView(
                            currentSolarProduction: $model.overviewData
                                .currentSolarProduction,
                            maximumSolarProduction: $solarProductionMaxValue
                        )

                        NetworkConsumptionView(
                            currentNetworkConsumption: $model.overviewData
                                .currentNetworkConsumption,
                            maximumNetworkConsumption:
                                $networkProductionMaxValue
                        )
                    }

                    HStack(spacing: 50) {

                        if $model.overviewData.currentBatteryLevel.wrappedValue
                            != nil
                            && $model.overviewData
                                .currentBatteryChargeRate.wrappedValue != nil
                        {

                            BatteryView(
                                currentBatteryLevel: $model.overviewData
                                    .currentBatteryLevel,
                                currentChargeRate: $model.overviewData
                                    .currentBatteryChargeRate
                            )
                        }

                        HouseholdConsumptionView(
                            currentOverallConsumption: $model.overviewData
                                .currentOverallConsumption,
                            consumptionMaxValue: $networkProductionMaxValue
                        )
                    }
                }

                HStack {
                    Text(
                        model.lastUpdatedAt?.formatted() ?? "-"
                    )
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                }.padding(.top, 10)
            }
            .padding()
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in
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
