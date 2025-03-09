import SwiftUI

struct ContentView: View {
    @Environment(CurrentBuildingState.self) var viewModel: CurrentBuildingState
    @State var showAppRateRequest = AppStoreReviewManager.shared
        .checkAndRequestReview()
    @State private var loginCredentialsCheckTimer: Timer?

    var body: some View {

        let mainTab = Binding<MainTab>(
            get: { viewModel.selectedMainTab },
            set: { viewModel.selectedMainTab = $0 }
        )

        if !viewModel.loginCredentialsExists {
            LoginView()
                .onAppear {
                    if loginCredentialsCheckTimer == nil {
                        loginCredentialsCheckTimer = Timer.scheduledTimer(
                            withTimeInterval: 5, repeats: true
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
                TabView(selection: mainTab) {
                    OverviewView()
                        .onTapGesture {
                            print("Force refresh")
                            Task {
                                await viewModel.fetchServerData()
                            }
                        }
                        .tag(MainTab.overview)

                    if viewModel.overviewData.hasAnyCarChargingStation {
                        ChargingControlView()
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
                            .tag(MainTab.charging)
                    }

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
                        .tag(MainTab.solarProduction)

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
            viewModel.setMainTab(newTab: .overview)
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
                    chargingStations: []
                ))
        )
}

#Preview("Login Form") {
    ContentView()
        .environment(CurrentBuildingState.fake(
            loggedIn: false
        ))
}
