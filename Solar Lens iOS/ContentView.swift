//
//  ContentView.swift
//  Solar Lens iOS
//
//  Created by Marc Dürst on 31.12.2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = BuildingStateViewModel()

    var body: some View {
        if viewModel.isLoading {
            ProgressView()
                .tint(.accent)
                .padding()
                .foregroundStyle(.accent)
                .background(Color.black.opacity(0.7))
        } else if !viewModel.loginCredentialsExists {
            VStack {
                Text("No login!")
                    .foregroundColor(.red)
                    .font(.title)
            }
        } else {
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Hello, world!")
                
                Text("Current Consumption: \(viewModel.overviewData.currentOverallConsumption)")
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
