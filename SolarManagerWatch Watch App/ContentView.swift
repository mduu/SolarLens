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

        if !viewModel.loginCredentialsExists {
            LoginView()
                .environmentObject(viewModel)
        } else if viewModel.loginCredentialsExists {

            TabView {
                HStack {
                    OverviewView()
                        .environmentObject(viewModel)
                        .background(Color.black.opacity(1.0))
                        .onTapGesture {
                            print("Force refresh")
                            Task {
                                await viewModel.fetchServerData()
                            }
                        }
                }

                ChargingControlView()
                    .environmentObject(viewModel)
                
                Settings()
                    .environmentObject(viewModel)

            }
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
