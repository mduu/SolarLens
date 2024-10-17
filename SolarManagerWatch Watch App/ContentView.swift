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

        if viewModel.error != nil || viewModel.errorMessage != nil {
            ScrollView {
                VStack {
                    if viewModel.error == EnergyManagerClientError.loginFailed {
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
                    } else {
                        Text("Errpr occured!")
                            .foregroundStyle(Color.red)
                            .font(.title3)
                        Text("Something went wrong! \(viewModel.errorMessage ?? "")")
                            .font(.subheadline)
                        Button("Try again") {
                            Task {
                                await viewModel.fetchServerData()
                            }
                        }
                        Button("Log out") {
                            viewModel.logout()
                        }
                    }
                }
            }

        } else if !viewModel.loginCredentialsExists {
            LoginView()
                .environmentObject(viewModel)
        } else if viewModel.isLoggedIn {

            TabView {
                OverviewView()
                    .environmentObject(viewModel)
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
                .onAppear() {
                    Task {
                        await viewModel.fetchServerData()
                    }
                }
        }
    }
}

#Preview {
    ContentView()
}
