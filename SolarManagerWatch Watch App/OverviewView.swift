//
//  OverviewView.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 29.09.2024.
//

import SwiftUI

struct OverviewView: View {
    @EnvironmentObject var model: BuildingStateViewModel

    @State private var solarProductionMinValue = 0.0
    @State private var solarProductionMaxValue = 11.0
    @State private var networkProductionMaxValue = 20.0
    @State private var consumptionMaxValue = 15.0

    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                gradient: getBackgroundGRadient(),
                startPoint: .top,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)

            // Other controls on top of background
            VStack {
                VStack() {
                    VStack() {
                        Gauge(
                            value: model.overviewData.currentSolarProduction,
                            in:
                                solarProductionMinValue...solarProductionMaxValue
                        ) {
                            Text("kW")
                        } currentValueLabel: {
                            Text(
                                String(
                                    format: "%.1f",
                                    model.overviewData.currentSolarProduction)
                            )
                        }
                        .gaugeStyle(.circular)
                        .if(shouldInvertColor()) {view in
                            view.colorInvert()
                        }

                        Image(systemName: "sun.max")
                            .if(shouldInvertColor()) { view in
                                view.colorInvert()
                            }
                    }

                    HStack(spacing: 50) {
                        VStack(spacing: 1) {
                            Gauge(
                                value: model.overviewData.currentBatteryLevel,
                                in: 0...100
                            ) {
                                Text("Bat")
                            } currentValueLabel: {
                                Text(
                                    String(
                                        format: "%.0f%%",
                                        model.overviewData.currentBatteryLevel)
                                )
                            }
                            .gaugeStyle(.accessoryCircularCapacity)
                            .if(shouldInvertColor()) { view in
                                view.colorInvert()
                            }
                            
                            Image(systemName: "battery.100percent")
                                .if(shouldInvertColor()) { view in
                                    view.colorInvert()
                                }
                        }
                        
                        VStack(spacing: 1) {
                            Gauge(
                                value: model.overviewData.currentNetworkConsumption,
                                in: 0...networkProductionMaxValue
                            ) {
                                Text("kWh")
                            } currentValueLabel: {
                                Text(
                                    String(
                                        format: "%.0f",
                                        model.overviewData.currentNetworkConsumption)
                                )
                            }
                            .gaugeStyle(.accessoryCircular)
                            .if(shouldInvertColor()) { view in
                                view.colorInvert()
                            }
                            
                            Image(systemName: "network")
                                .if(shouldInvertColor()) { view in
                                    view.colorInvert()
                                }
                        }
                    }
                    VStack(spacing: 0) {
                        Gauge(
                            value: model.overviewData.currentOverallConsumption,
                            in:
                                0...consumptionMaxValue
                        ) {
                            Text("kW")
                        } currentValueLabel: {
                            Text(
                                String(
                                    format: "%.1f",
                                    model.overviewData.currentOverallConsumption)
                            )
                        }
                        .gaugeStyle(.circular)
                        .if(shouldInvertColor()) {view in
                            view.colorInvert()
                        }

                        Image(systemName: "house")
                            .if(shouldInvertColor()) { view in
                                view.colorInvert()
                            }
                    }
                }
            }
            .padding()
        }
    }

    private func solarPercentage() -> Double {
        return 100 / solarProductionMaxValue * model.overviewData.currentSolarProduction;
    }

    private func shouldInvertColor() -> Bool {
        return solarPercentage() >= 40
            ? true
            : false
    }

    private func getBackgroundGRadient() -> Gradient {
        if solarPercentage() >= 40 {
            return Gradient(colors: [.yellow, .red])
        }

        if solarPercentage() >= 10 {
            return Gradient(colors: [.orange, .orange.opacity(0.4)])
        }

        if solarPercentage() >= 1 {
            return Gradient(colors: [
                .orange.opacity(0.8), .orange.opacity(0.1),
            ])
        }

        return Gradient(colors: [.blue.opacity(0.5), .black])
    }
}

extension View {
    @ViewBuilder func `if`<Content: View>(
        _ condition: Bool, transform: (Self) -> Content
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

#Preview {
    OverviewView()
        .environmentObject(
            BuildingStateViewModel(
                solarManagerClient: FakeEnergyManager()
            ))
}
