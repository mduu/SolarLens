import SwiftUI

struct HomeView: View {
    @Environment(CurrentBuildingState.self) var buildingState: CurrentBuildingState
    @Environment(\.colorScheme) var colorScheme
    @State private var refreshTimer: Timer?
    @State private var showLogoutConfirmation: Bool = false

    var body: some View {
        VStack {
            if buildingState.isLoading
                && buildingState.overviewData.lastSuccessServerFetch == nil
            {
                ProgressView()
                    .tint(.accent)
                    .padding()
                    .foregroundStyle(.accent)
                    .background(Color.black.opacity(0.3))
            } else {
                ZStack {

                    BackgroundView()

                    HeaderView()
                    
                    VStack {
                        HStack {
                            Spacer()
                            
                            Button("Log out", systemImage: "iphone.and.arrow.right.outward")
                            {
                                showLogoutConfirmation = true
                            }.labelStyle(.iconOnly)
                                .buttonStyle(.borderless)
                                .foregroundColor(.primary)
                                .font(.system(size: 24))
                                .confirmationDialog(
                                    "Are you sure to log out?",
                                    isPresented: $showLogoutConfirmation
                                ) {
                                    Button("Confirm") {
                                        buildingState.logout()
                                    }
                                    Button("Cancel", role: .cancel) {}
                                }
                        }.padding().padding(.trailing)
                        
                        Spacer()
                    } // :VStack
                    
                    VStack {
                        Spacer()
                        UpdateTimeStampView(
                            isStale: buildingState.overviewData.isStaleData,
                            updateTimeStamp: buildingState.overviewData.lastSuccessServerFetch,
                            isLoading: buildingState.isLoading
                        )
                    } // :VStack

                    VStack {

                        let solar =
                            Double(
                                buildingState.overviewData.currentSolarProduction)
                            / 1000
                        
                        let consumption =
                            Double(
                                buildingState.overviewData.currentOverallConsumption)
                            / 1000
                        
                        let grid =
                            Double(
                                buildingState.overviewData.currentGridToHouse >= 0
                                ? buildingState.overviewData.currentGridToHouse
                                : buildingState.overviewData.currentSolarToGrid)
                            / 1000
                                                
                        Grid(horizontalSpacing: 2, verticalSpacing: 20) {
                            GridRow {
                                SolarForecastView()
                                    .frame(maxWidth: 150, maxHeight: 100)
                                                                
                                Text("")
                            }
                            GridRow(alignment: .center) {
                                CircularInstrument(
                                    borderColor: Color.accentColor,
                                    label: "Solar Production",
                                    value: String(format: "%.1f kW", solar)
                                ) {
                                    Image(systemName: "sun.max").foregroundColor(.black)
                                }
                                .frame(maxWidth: 120, maxHeight: 120)

                                if buildingState.overviewData.isFlowSolarToGrid() {
                                    Image(systemName: "arrow.right")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 50, weight: .light))
                                        .symbolEffect(
                                            .wiggle.byLayer,
                                            options: .repeat(.periodic(delay: 0.7)))
                                } else {
                                    Text("")
                                        .frame(minWidth: 50, minHeight: 50)
                                }
                                
                                CircularInstrument(
                                    borderColor: Color.orange,
                                    label: "Grid",
                                    value: String(format: "%.1f kW", grid)
                                ) {
                                    Image(systemName: "network").foregroundColor(.black)
                                }
                                .frame(maxWidth: 120, maxHeight: 120)
                            } // :GridRow
                            
                            GridRow(alignment: .center) {
                                if buildingState.overviewData.isFlowSolarToBattery() {
                                    Image(systemName: "arrow.down")
                                        .foregroundColor(.green)
                                        .font(.system(size: 50, weight: .light))
                                        .symbolEffect(
                                            .wiggle.byLayer,
                                            options: .repeat(.periodic(delay: 0.7)))

                                } else {
                                    Text("")
                                        .frame(minWidth: 50, minHeight: 50)
                                }

                                if buildingState.overviewData.isFlowSolarToHouse() {
                                    Image(systemName: "arrow.down.right")
                                        .foregroundColor(.green)
                                        .font(.system(size: 50, weight: .light))
                                        .symbolEffect(
                                            .wiggle.byLayer,
                                            options: .repeat(.periodic(delay: 0.7)))
                                } else {
                                    Text("")
                                        .frame(minWidth: 50, minHeight: 50)
                                }

                                if buildingState.overviewData.isFlowGridToHouse() {
                                    Image(systemName: "arrow.down")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 50, weight: .light))
                                        .symbolEffect(
                                            .wiggle.byLayer,
                                            options: .repeat(.periodic(delay: 0.7)))
                                } else {
                                    Text("")
                                        .frame(minWidth: 50, minHeight: 50)
                                }
                            } // :GridRow
                                .frame(minWidth: 30, minHeight: 20)
                            
                            GridRow(alignment: .center) {
                                if buildingState.overviewData.currentBatteryLevel != nil {
                                    BatteryBoubleView(
                                        currentBatteryLevel: buildingState.overviewData.currentBatteryLevel,
                                        currentChargeRate: buildingState.overviewData.currentBatteryChargeRate
                                    )
                                } else {
                                    Text("")
                                        .frame(minWidth: 120, minHeight: 120)
                                }
                                
                                if buildingState.overviewData.isFlowBatteryToHome() {
                                    Image(systemName: "arrow.right")
                                        .foregroundColor(.green)
                                        .font(.system(size: 50, weight: .light))
                                        .symbolEffect(
                                            .wiggle.byLayer,
                                            options: .repeat(.periodic(delay: 0.7)))
                                } else {
                                    Text("")
                                        .frame(minWidth: 50, minHeight: 50)
                                }
                                
                                CircularInstrument(
                                    borderColor: Color.teal,
                                    label: "Consumption",
                                    value: String(format: "%.1f kW", consumption)
                                ) {
                                    Image(systemName: "house").foregroundColor(.black)
                                }
                                .frame(maxWidth: 120, maxHeight: 120)
                            } // :GridRow
                            
                            GridRow {
                                
                                Text("")
                                
                                Text("")
                                
                                VStack {
                                    if buildingState.overviewData.isAnyCarCharing {
                                        Image(systemName: "arrow.down")
                                            .foregroundColor(.blue)
                                            .font(.system(size: 25, weight: .light))
                                            .symbolEffect(
                                                .wiggle.byLayer,
                                                options: .repeat(.periodic(delay: 0.7)))
                                    } else {
                                        Text("")
                                            .frame(minHeight: 25)
                                    }
                                    
                                    ChargingStationsView(chargingStation: buildingState.overviewData.chargingStations)
                                        .frame(maxWidth: 120)
                                }
                                
                            }
                            
                        } // :Grid
                    } // :VStack
                    .padding(.top, 70)
                    
                    VStack {
                        Spacer()
                        SiriDiscoveryView()
                    }.padding(.bottom, 5)
                }  // :ZStack
            }
        }
        .onAppear {
            if buildingState.overviewData.lastSuccessServerFetch == nil {
                print("fetch on appear")
                Task {
                    await buildingState.fetchServerData()
                }
            }

            if refreshTimer == nil {
                refreshTimer = Timer.scheduledTimer(
                    withTimeInterval: 15, repeats: true
                ) {
                    _ in
                    Task {
                        print("fetch on timer")
                        await buildingState.fetchServerData()
                    }
                }  // :refreshTimer
            }  // :if
        }
    }
}

#Preview {
    HomeView()
        .environment(
            CurrentBuildingState.fake(
                overviewData: OverviewData.fake()))
}




