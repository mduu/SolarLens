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

        if viewModel.error == EnergyManagerClientError.loginFailed
            || viewModel.errorMessage != nil
        {
            ScrollView {
                VStack(alignment: HorizontalAlignment.leading) {
                    Text("Login failed!")
                        .foregroundStyle(Color.red)
                        .font(.title3)

                    Text(
                        "Please make sure you are using the correct email and passwort from your Solar Manager login."
                    )
                    .padding(.top, 5)
                    .padding(.bottom, 5)
                    .font(.subheadline)

                    Button("Retry login") {
                        viewModel.logout()
                    }
                }
            }

        } else if !viewModel.loginCredentialsExists {
            LoginView()
                .environmentObject(viewModel)
        } else if viewModel.isLoggedIn {

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

                //                ProductionView()
                //                    .environmentObject(viewModel)
                //                ConsumationView()
                //                    .environmentObject(viewModel)
                Settings()
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
