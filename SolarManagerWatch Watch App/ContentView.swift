import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = BuildingStateViewModel()

    var body: some View {

        if !viewModel.loginCredentialsExists {
            LoginView()
                .environmentObject(viewModel)
        } else if viewModel.loginCredentialsExists {

            NavigationView {
                TabView(selection: $viewModel.selectedMainTab) {
                    OverviewView()
                        .environmentObject(viewModel)
                        .onTapGesture {
                            print("Force refresh")
                            Task {
                                await viewModel.fetchServerData()
                            }
                        }
                        .tag(0)

                    ChargingControlView()
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
                        .tag(1)

                    SolarDetailsView()
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
                        .tag(2)

                }  // :TabView
                .tabViewStyle(.verticalPage(transitionStyle: .blur))

            }  // :NavigationView
            .edgesIgnoringSafeArea(.all)
        
        } else {
            ProgressView()
                .tint(.accent)
                .padding()
                .foregroundStyle(.accent)
                .background(Color.black.opacity(0.7))
        }
    }

    fileprivate func HomeButton() -> some View {
        return Button {
            viewModel.setMainTab(newTab: .overview)
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
