import SwiftUI

struct OverviewView: View {
    @Environment(CurrentBuildingState.self) private var model

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
                                    options: .repeat(.continuous))
                                .accessibilityLabel("A connection error occurred!")
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
                    Grid {
                        GridRow(alignment: .center) {
                            SolarProductionView(
                                currentSolarProduction: model.overviewData
                                    .currentSolarProduction,
                                maximumSolarProduction: model.overviewData
                                    .solarProductionMax
                            )
                            .onTapGesture {
                                model.setMainTab(newTab: .solarProduction)
                            }

                            if model.overviewData.isFlowSolarToGrid() {
                                Image(systemName: "arrow.right")
                                    .foregroundColor(.orange)
                                    .symbolEffect(
                                        .wiggle.byLayer,
                                        options: .repeat(.periodic(delay: 0.7)))
                            } else {
                                Text("")
                            }

                            NetworkConsumptionView(
                                currentNetworkConsumption: model.overviewData
                                    .currentGridToHouse,
                                currentNetworkFeedin: model.overviewData
                                    .currentSolarToGrid,
                                isFlowFromNetwork: model.overviewData
                                    .isFlowGridToHouse(),
                                isFlowToNetwork: model.overviewData
                                    .isFlowSolarToGrid()
                            )
                        }

                        GridRow(alignment: .center) {
                            if model.overviewData.isFlowSolarToBattery() {
                                Image(systemName: "arrow.down")
                                    .foregroundColor(.green)
                                    .symbolEffect(
                                        .wiggle.byLayer,
                                        options: .repeat(.periodic(delay: 0.7)))
                            } else {
                                Text("")
                            }

                            if model.overviewData.isFlowSolarToHouse() {
                                Image(systemName: "arrow.down.right")
                                    .foregroundColor(.green)
                                    .symbolEffect(
                                        .wiggle.byLayer,
                                        options: .repeat(.periodic(delay: 0.7)))
                            } else {
                                Text("")
                            }

                            if model.overviewData.isFlowGridToHouse() {
                                Image(systemName: "arrow.down")
                                    .foregroundColor(.orange)
                                    .symbolEffect(
                                        .wiggle.byLayer,
                                        options: .repeat(.periodic(delay: 0.7)))
                            } else {
                                Text("")
                            }
                        }.frame(minWidth: 30, minHeight: 20)

                        GridRow(alignment: .center) {

                            BatteryView(
                                currentBatteryLevel: model.overviewData
                                    .currentBatteryLevel,
                                currentChargeRate: model.overviewData
                                    .currentBatteryChargeRate
                            )

                            if model.overviewData.isFlowBatteryToHome() {
                                Image(systemName: "arrow.right")
                                    .foregroundColor(.green)
                                    .symbolEffect(
                                        .wiggle.byLayer,
                                        options: .repeat(.periodic(delay: 0.7)))
                            } else {
                                Text("")
                            }

                            HouseholdConsumptionView(
                                currentOverallConsumption: model.overviewData
                                    .currentOverallConsumption,
                                isAnyCarCharging: model.overviewData
                                    .isAnyCarCharing
                            )
                            .onTapGesture {
                                model.setMainTab(newTab: .consumption)
                            }
                        }
                    }  // :Grid
                    .padding(.top, 10)
                    .padding(.bottom, 0)
                    .padding(.leading, 10)
                    .padding(.trailing, 10)

                    UpdateTimeStampView(
                        isStale: model.overviewData.isStaleData,
                        updateTimeStamp: model.overviewData.lastUpdated,
                        isLoading: model.isLoading
                    )
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
                }  // :VStack
            }  // :ZStack
        }  // :VStack
    }
}

#Preview("English") {
    OverviewView()
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
}

#Preview("Stale data") {
    OverviewView()
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
}

#Preview("Loading") {
    OverviewView()
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
}

#Preview("German") {
    OverviewView()
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
        .environment(\.locale, Locale(identifier: "DE"))
}
