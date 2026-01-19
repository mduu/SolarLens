import SwiftUI

struct ContentView: View {
    @Environment(CurrentBuildingState.self) var viewModel
    @Environment(NavigationState.self) var navigationState
    @State var showAppRateRequest = AppStoreReviewManager.shared
        .checkAndRequestReview()
    @State private var loginCredentialsCheckTimer: Timer?
    
    // Survey Logic
    @State var showSurvey: Bool = false
    @AppStorage("surveyForeverDismissed") var surveyForeverDismissed: Bool = false
    @AppStorage("surveyLastShownDate") var surveyLastShownDate: Double = 0.0

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

            ZStack {
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

                        if viewModel.overviewData.hasAnyBattery {
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
                        }

                        GridScreen()
                            .toolbar {
                                ToolbarItem(placement: .topBarLeading) {
                                    HStack {
                                        HomeButton()

                                        Text("Grid")
                                            .foregroundColor(.indigo)
                                            .font(.headline)

                                        Spacer()
                                    }  // :HStack
                                }  // :ToolbarItem
                            }  // :.toolbar
                            .tag(5)


                    }  // :TabView
                    .tabViewStyle(.verticalPage(transitionStyle: .blur))
                    .sheet(isPresented: $showAppRateRequest) {
                        AppReviewRequestView()
                    }

                }  // :NavigationView
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    if viewModel.overviewData.isOutdatedData {
                        print("Fetching onAppear because outdated data")
                        Task {
                            await viewModel.fetchServerData()
                        }
                    }
                    checkSurveyDisplay()
                }

                if showSurvey {
                    WatchSurveyView(isPresented: $showSurvey.animation())
                        .zIndex(1)
                }
            }

        } else {
            ProgressView()
                .tint(.accent)
                .padding()
                .foregroundStyle(.accent)
                .background(Color.black.opacity(0.7))
        }
    }

    private func checkSurveyDisplay() {
        let now = Date()
        var dateComponents = DateComponents()
        dateComponents.year = 2026
        dateComponents.month = 3
        dateComponents.day = 31
        
        guard let endDate = Calendar.current.date(from: dateComponents) else { return }
        
        if now > endDate { return }
        if surveyForeverDismissed { return }
        
        if surveyLastShownDate > 0 {
            let lastShown = Date(timeIntervalSince1970: surveyLastShownDate)
            if now.timeIntervalSince(lastShown) < 86400 {
                return
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showSurvey = true
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
