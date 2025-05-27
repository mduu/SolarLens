import SwiftUI

struct ContentView: View {
    @Environment(CurrentBuildingState.self) var viewModel
    @Environment(NavigationState.self) var navigationState
    @State var showAppRateRequest = AppStoreReviewManager.shared
        .checkAndRequestReview()
    @State private var loginCredentialsCheckTimer: Timer?

    var body: some View {

        if !viewModel.loginCredentialsExists {
            LoginScreen()
                .onAppear {
                    if loginCredentialsCheckTimer == nil {
                        loginCredentialsCheckTimer = Timer.scheduledTimer(
                            withTimeInterval: 5,
                            repeats: true
                        ) {
                            _ in
                            Task {
                                print("Timer check for credentials")
                                await viewModel.checkForCredentions()
                                if await viewModel.loginCredentialsExists {
                                    await disableLoginCredentialsCheckTimer()
                                }
                            }
                        }  // :refreshTimer
                    }  // :if
                }
        } else if viewModel.loginCredentialsExists {

            NavigationView {
                TabView(
                    selection: Binding(
                        get: { navigationState.selectedTab },
                        set: { navigationState.selectedTab = $0 }
                    )
                ) {
                    OverviewScreen()
                        .onTapGesture {
                            print("Force refresh")
                            Task {
                                await viewModel.fetchServerData()
                            }
                        }
                        .tag(0)

                    if viewModel.overviewData.hasAnyCarChargingStation {
                        ChargingScreen()
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
                    }

                    SolarScreen()
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

                    ConsumptionScreen()
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                HStack {
                                    HomeButton()

                                    Text("Consumption")
                                        .foregroundColor(.cyan)
                                        .font(.headline)

                                    Spacer()
                                }  // :HStack
                            }  // :ToolbarItem
                        }  // :.toolbar
                        .tag(3)

                    BatteryScreen()
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                HStack {
                                    HomeButton()

                                    Text("Battery")
                                        .foregroundColor(.purple)
                                        .font(.headline)

                                    Spacer()
                                }  // :HStack
                            }  // :ToolbarItem
                        }  // :.toolbar
                        .tag(4)

                }  // :TabView
                .tabViewStyle(.verticalPage(transitionStyle: .blur))
                .sheet(isPresented: $showAppRateRequest) {
                    AppReviewRequestView()
                }

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

    func disableLoginCredentialsCheckTimer() {
        loginCredentialsCheckTimer?.invalidate()
        loginCredentialsCheckTimer = nil
        print("Disabled loginCredentialsCheckTimer")
    }

    fileprivate func HomeButton() -> some View {
        return Button {
            navigationState.navigate(to: .overview)
        } label: {
            Image(systemName: "chevron.up")
        }
        .buttonStyle(.plain)
        .buttonBorderShape(.circle)
    }
}

#Preview("Default") {
    ContentView()
        .environment(
            CurrentBuildingState.fake(
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
                    chargingStations: [],
                    devices: []
                )
            )
        )
}

#Preview("Login Form") {
    ContentView()
        .environment(
            CurrentBuildingState.fake(
                loggedIn: false
            )
        )
}
