import SwiftUI

struct OverviewScreen: View {
    @Environment(CurrentBuildingState.self) private var model
    @Environment(NavigationState.self) private var navigationState

    @State private var refreshTimer: Timer?
    @State private var showSettings: Bool = false
    @State private var showChart: Bool = false

    var body: some View {
        VStack {
            ZStack {
                VStack {
                    HStack {
                        if model.overviewData.hasConnectionError {
                            Image(systemName: "exclamationmark.icloud")
                                .foregroundColor(Color.red)
                                .symbolEffect(
                                    .pulse.wholeSymbol,
                                    options: .repeat(.continuous)
                                )
                                .accessibilityLabel(
                                    "A connection error occurred!")
                        }

                        if model.error != nil {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(Color.yellow)
                                .symbolEffect(.breathe.wholeSymbol)
                                .accessibilityLabel("A general error occurred!")
                        }
                    }

                    Spacer()
                }  // :VStack
                
                VStack {
                    Spacer()
                    
                    UpdateTimeStampView(
                        isStale: model.overviewData.isStaleData,
                        updateTimeStamp: model.overviewData.lastUpdated,
                        isLoading: model.isLoading
                    )
                    .padding(.bottom, -9)
                }

                VStack {
                    EnergyFlowView()
                        .padding(.bottom, 17)
                        .padding(.top, 8)
                }  // :VStack
                .onAppear {
                    Task {
                        await model.fetchServerData()
                    }
                    if refreshTimer == nil {
                        refreshTimer = Timer.scheduledTimer(
                            withTimeInterval: 15, repeats: true
                        ) {
                            _ in
                            Task {
                                await model.fetchServerData()
                            }
                        }  // :refreshTimer
                    }  // :if
                }  // :OnAppear

                VStack {

                    Spacer()

                    HStack {
                        Button(action: {
                            model.pauseFetching()
                            withAnimation {
                                showChart = true
                            }
                        }) {
                            Image(
                                systemName: "chart.line.uptrend.xyaxis.circle"
                            )
                            .resizable()
                            .scaledToFit()
                            .frame(width: 15, height: 15)
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.primary)
                        .padding(.leading, 12)
                        .sheet(isPresented: $showChart) {
                            OverviewChartView()
                                .onDisappear {
                                    model.resumeFetching()
                                }

                        }

                        Spacer()

                        Button(action: {
                            model.pauseFetching()
                            withAnimation {
                                showSettings = true
                            }
                        }) {
                            Image(systemName: "gear")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 15, height: 15)
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.primary)
                        .padding(.trailing, 12)
                        .sheet(isPresented: $showSettings) {
                            SettingsView()
                                .onDisappear {
                                    model.resumeFetching()
                                }  // :SettingsView
                                .toolbar {
                                    ToolbarItem(placement: .topBarTrailing) {
                                        Text("Settings")
                                            .foregroundColor(.accentColor)
                                            .font(.headline)
                                    }  // :ToolbarItem
                                }  // :.toolbar
                        }  // :sheet
                    }  // :HStack
                    .padding(.bottom, -7)
                }  // :VStack
            }  // :ZStack
        }  // :VStack
    }
}

#Preview("English") {
    OverviewScreen()
        .environment(
            CurrentBuildingState.fake(
                overviewData: .init(
                    currentSolarProduction: 4500,
                    currentOverallConsumption: 400,
                    currentBatteryLevel: 78,
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
        .environment(NavigationState.init())
}

#Preview("Stale data") {
    OverviewScreen()
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
                    lastUpdated: Calendar.current.date(
                        byAdding: .minute, value: -40, to: Date()),
                    lastSuccessServerFetch: Date(),
                    isAnyCarCharing: false,
                    chargingStations: [],
                    devices: []
                )
            )
        )
        .environment(NavigationState.init())
}

#Preview("Loading") {
    OverviewScreen()
        .environment(
            CurrentBuildingState.fake(
                overviewData: .init(
                    currentSolarProduction: 4500,
                    currentOverallConsumption: 400,
                    currentBatteryLevel: 78,
                    currentBatteryChargeRate: 150,
                    currentSolarToGrid: 3600,
                    currentGridToHouse: 50,
                    currentSolarToHouse: 400,
                    solarProductionMax: 11000,
                    hasConnectionError: false,
                    lastUpdated: Date(),
                    lastSuccessServerFetch: Date(),
                    isAnyCarCharing: true,
                    chargingStations: [],
                    devices: []
                ),
                isLoading: true
            )
        )
        .environment(NavigationState.init())
}

#Preview("German") {
    OverviewScreen()
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
        .environment(NavigationState.init())
        .environment(\.locale, Locale(identifier: "DE"))
}
