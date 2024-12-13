import SwiftUI

enum Tab {
    case overview, charging, solar
}

struct ContentView: View {
    @StateObject var viewModel = BuildingStateViewModel()
    @State private var selectedTab: Tab = .overview

    var body: some View {

        if !viewModel.loginCredentialsExists {
            LoginView()
                .environmentObject(viewModel)
        } else if viewModel.loginCredentialsExists {

            NavigationView {
                TabView(selection: $selectedTab) {
                    OverviewView()
                        .environmentObject(viewModel)
                        .onTapGesture {
                            print("Force refresh")
                            Task {
                                await viewModel.fetchServerData()
                            }
                        }
                        .tag(Tab.overview)

                    ChargingControlView()
                        .tag(Tab.charging)
                        .environmentObject(viewModel)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                HStack {
                                    Button {
                                        selectedTab = .overview
                                    } label: {
                                        Image(systemName: "chevron.left")
                                            .foregroundColor(.green)
                                    }
                                    
                                    Text("Charging")
                                        .foregroundColor(.green)
                                        .font(.headline)
                                } // :HStack
                            } // :ToolbarItem
                        } // :.toolbar
                    
                    SolarDetailsView()
                        .tag(Tab.solar)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                HStack {
                                    Button {
                                        selectedTab = .overview
                                    } label: {
                                        Image(systemName: "chevron.left")
                                            .foregroundColor(.orange)
                                    }
                                    
                                    Text("Solar")
                                        .foregroundColor(.orange)
                                        .font(.headline)
                                } // :HStack
                            } // :ToolbarItem
                        } // :.toolbar

                }  // :TabView
                .tabViewStyle(.verticalPage(transitionStyle: .blur))

            }  // :NavigationView
            .edgesIgnoringSafeArea(.all)

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
