import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = BuildingStateViewModel()
    @State private var selectedTab = 0

    var body: some View {

        if !viewModel.loginCredentialsExists {
            LoginView()
                .environmentObject(viewModel)
        } else if viewModel.loginCredentialsExists {

            NavigationView {
                TabView(selection: $selectedTab) {
                    OverviewView()
                        .tag(0)
                        .environmentObject(viewModel)
                        .onTapGesture {
                            print("Force refresh")
                            Task {
                                await viewModel.fetchServerData()
                            }
                        }

                    ChargingControlView()
                        .tag(1)
                        .environmentObject(viewModel)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                HStack {
                                    HomeButton()

                                    Text("Charging")
                                        .foregroundColor(.green)
                                        .font(.headline)

                                    Spacer()
                                }  // :HStack
                            }  // :ToolbarItem
                        }  // :.toolbar

                    SolarDetailsView()
                        .tag(2)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                HStack {
                                    HomeButton()

                                    Text("Solar")
                                        .foregroundColor(.orange)
                                        .font(.headline)

                                    Spacer()
                                }  // :HStack
                            }  // :ToolbarItem
                        }  // :.toolbar

                }  // :TabView
                .tabViewStyle(.verticalPage(transitionStyle: .blur))
                .onAppear {
                    selectedTab = 0
                    print("!!!!! onApear")
                }

            }  // :NavigationView
            .edgesIgnoringSafeArea(.all)
            .onDisappear {
                selectedTab = 0
                print("???? onDisapear")
            }
        } else {
            ProgressView()
                .onAppear {
                    selectedTab = 0
                    Task {
                        await viewModel.fetchServerData()
                    }
                }
        }
    }

    fileprivate func HomeButton() -> some View {
        return Button {
            selectedTab = 0
        } label: {
            Image(systemName: "chevron.up")
        }
        .buttonStyle(.plain)
        .buttonBorderShape(.circle)
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
