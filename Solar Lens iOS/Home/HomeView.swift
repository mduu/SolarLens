//
//  HomeView.swift
//  Solar Lens
//
//  Created by Marc Dürst on 01.01.2025.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: BuildingStateViewModel
    @State private var refreshTimer: Timer?

    var body: some View {
        VStack {
            if viewModel.isLoading
                && viewModel.overviewData.lastSuccessServerFetch == nil
            {
                ProgressView()
                    .tint(.accent)
                    .padding()
                    .foregroundStyle(.accent)
                    .background(Color.black.opacity(0.3))
            } else {
                ZStack {

                    Image("OverviewFull")
                        .resizable()
                        .scaledToFill()
                        .saturation(0.6)
                        .ignoresSafeArea()

                    VStack {
                        Spacer()

                        HStack(alignment: .center) {
                            Image("solarlens")
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(5)
                                .frame(maxWidth: 50)

                            VStack(alignment: .leading) {

                                Text("Solar")
                                    .foregroundColor(.accent)
                                    .font(.system(size: 24, weight: .bold))

                                Text("Lens")
                                    .foregroundColor(.white)
                                    .font(.system(size: 24, weight: .bold))

                            }

                        }  // :HStack

                    }  // :VStack

                    VStack {

                        var solar =
                            Double(
                                viewModel.overviewData.currentSolarProduction)
                            / 1000
                        
                        var consumption =
                            Double(
                                viewModel.overviewData.currentOverallConsumption)
                            / 1000
                        
                        var grid =
                            Double(
                                viewModel.overviewData.currentGridToHouse >= 0
                                ? viewModel.overviewData.currentGridToHouse
                                : viewModel.overviewData.currentSolarToGrid)
                            / 1000
                        
                        var battery = viewModel.overviewData.currentBatteryLevel ?? 0
                        
                        HStack(spacing: 50) {
                            CircularInstrument(
                                borderColor: Color.accentColor,
                                label: "Solar Production",
                                value: String(format: "%.1f kW", solar)
                            )
                            
                            CircularInstrument(
                                borderColor: Color.orange,
                                label: "Grid",
                                value: String(format: "%.1f kW", grid)
                            )
                        }
                        .padding(.top, 50)
                        
                        HStack(spacing: 50) {
                            CircularInstrument(
                                borderColor: Color.green,
                                label: "Battery",
                                value: String(format: "%.0f %%", battery)
                            )
                            
                            CircularInstrument(
                                borderColor: Color.teal,
                                label: "Consumption",
                                value: String(format: "%.1f kW", consumption)
                            )
                        }
                        .padding(.top, 100)
                        
                        Spacer()

                    }  // :VStack
                    .padding(.top, 50)
                }  // :ZStack
            }
        }
        .onAppear {
            if viewModel.overviewData.lastSuccessServerFetch == nil {
                print("fetch on appear")
                Task {
                    await viewModel.fetchServerData()
                }
            }

            if refreshTimer == nil {
                refreshTimer = Timer.scheduledTimer(
                    withTimeInterval: 15, repeats: true
                ) {
                    _ in
                    Task {
                        print("fetch on timer")
                        await viewModel.fetchServerData()
                    }
                }  // :refreshTimer
            }  // :if
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(
            BuildingStateViewModel.fake(
                overviewData: OverviewData.fake()))
}
