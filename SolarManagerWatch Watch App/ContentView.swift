//
//  ContentView.swift
//  SolarManagerWatch Watch App
//
//  Created by Marc Dürst on 28.09.2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = BuildingStateViewModel()

    var body: some View {

        TabView {
            OverviewView()
                .environmentObject(viewModel)
            ProductionView()
                .environmentObject(viewModel)
            ConsumationView()
                .environmentObject(viewModel)
        }
        .tabViewStyle(
            .verticalPage(transitionStyle: .blur)
        )
        .onAppear {
            Task {
                await viewModel.fetchServerData()
            }
        }
    }
}

#Preview {
    ContentView()
}
