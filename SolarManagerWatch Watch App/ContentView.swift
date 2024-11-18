//
//  ContentView.swift
//  SolarManagerWatch Watch App
//
//  Created by Marc Dürst on 28.09.2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = BuildingStateViewModel()

    var body: some View {

        if !viewModel.loginCredentialsExists {
            LoginView()
                .environmentObject(viewModel)
        } else if viewModel.loginCredentialsExists {

            TabView() {
                OverviewView()
                    .environmentObject(viewModel)
                    .onTapGesture {
                        print("Force refresh")
                        Task {
                            await viewModel.fetchServerData()
                        }
                    }

                ChargingControlView()
                    .environmentObject(viewModel)

                SettingsView()
                    .environmentObject(viewModel)
                    .containerBackground(.black, for: .tabView)

            }  // :TabView
            .tabViewStyle(
                .verticalPage(transitionStyle: .blur)
            )

        } else {
            ProgressView()
                .onAppear {
                    Task {
                        await viewModel.fetchServerData()
                    }
                }
        }
    }
}

#Preview("Login Form") {
    ContentView()
}

#Preview("Logged in") {
    ContentView(
        viewModel: BuildingStateViewModel.fake(
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
                lastSuccessServerFetch: Date(),
                isAnyCarCharing: true,
                chargingStations: []
            ), loggedIn: true
        ))
}
