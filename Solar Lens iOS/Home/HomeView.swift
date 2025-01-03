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
            if viewModel.isLoading && viewModel.overviewData.lastSuccessServerFetch == nil {
                ProgressView()
                    .tint(.accent)
                    .padding()
                    .foregroundStyle(.accent)
                    .background(Color.black.opacity(0.3))
            } else {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Hello, world!")

                Text(
                    "Current Consumption: \(viewModel.overviewData.currentOverallConsumption)"
                )
            }
        }
        .padding()
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
