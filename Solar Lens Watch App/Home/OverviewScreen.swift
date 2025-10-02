import SwiftUI

struct OverviewScreen: View {
    @Environment(CurrentBuildingState.self) private var model
    @Environment(NavigationState.self) private var navigationState

    @State private var showSettings: Bool = false
    @State private var showChart: Bool = false

    let refreshTimer = Timer.publish(every: 15, on: .main, in: .common)
        .autoconnect()
    
    struct PressAwareHighlightStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                // Apply a visual change based on the isPressed state
                .background(configuration.isPressed ? Color.blue.opacity(0.5) : Color.clear)
                // You could also apply a border or shadow here
                // .border(configuration.isPressed ? Color.red : Color.clear, width: 2)
        }
    }

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
                                    "A connection error occurred!"
                                )
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
                        updateTimeStamp: model.overviewData.lastSuccessServerFetch,
                        isLoading: model.isLoading,
                        onRefresh: {
                            Task {
                                await model.fetchServerData()
                            }
                        }
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
                }  // :OnAppear
                .onReceive(refreshTimer) { inputDate in
                    Task {
                        await model.fetchServerData()
                    }
                }  // :onReceive

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
                        .padding(.leading, 8)
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
                        .padding(.trailing, 8)
                        .sheet(isPresented: $showSettings) {
                            SettingsView()
                                .onDisappear {
                                    model.resumeFetching()
                                }  // :SettingsView
                                .navigationTitle("Settings")
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
                        byAdding: .minute,
                        value: -40,
                        to: Date()
                    ),
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
