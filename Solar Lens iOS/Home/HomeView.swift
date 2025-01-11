import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: BuildingStateViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var refreshTimer: Timer?
    @State private var showLogoutConfirmation: Bool = false

    var body: some View {
        VStack {
            if viewModel.isLoading
                && viewModel.overviewData.lastSuccessServerFetch == nil
            {
                ProgressView()
                    .tint(.accent)
                    .padding()
                    .foregroundStyle(.accent)
                    .background(Color.black.opacity(0.3))
            } else {
                ZStack {

                    ZStack {
                        Rectangle()
                            .foregroundColor(colorScheme == .light ? .white : .black)
                            .ignoresSafeArea()
                        
                        Image("OverviewFull")
                            .resizable()
                            .clipped()
                            .saturation(0)
                            .opacity(colorScheme == .light ? 0.1 : 0.4)
                            .ignoresSafeArea()
                    }
                    

                    VStack {
                        HStack(alignment: .center) {
                            Image("solarlens")
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(5)
                                .frame(maxWidth: 50)

                            VStack(alignment: .leading) {

                                Text("Solar")
                                    .foregroundColor(.accent)
                                    .font(.system(size: 24, weight: .bold))

                                Text("Lens")
                                    .foregroundColor(colorScheme == .light ? .black : .white)
                                    .font(.system(size: 24, weight: .bold))

                            }

                        }  // :HStack
                        Spacer()

                    }  // :VStack
                    
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
                                        viewModel.logout()
                                    }
                                    Button("Cancel", role: .cancel) {}
                                }
                        }.padding().padding(.trailing)
                        
                        Spacer()
                    } // :VStack

                    VStack {

                        let solar =
                            Double(
                                viewModel.overviewData.currentSolarProduction)
                            / 1000
                        
                        let consumption =
                            Double(
                                viewModel.overviewData.currentOverallConsumption)
                            / 1000
                        
                        let grid =
                            Double(
                                viewModel.overviewData.currentGridToHouse >= 0
                                ? viewModel.overviewData.currentGridToHouse
                                : viewModel.overviewData.currentSolarToGrid)
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
                                    Image(systemName: "sun.max")
                                }
                                .frame(maxWidth: 120, maxHeight: 120)

                                if viewModel.overviewData.isFlowSolarToGrid() {
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
                                    Image(systemName: "network")
                                }
                                .frame(maxWidth: 120, maxHeight: 120)
                            } // :GridRow
                            
                            GridRow(alignment: .center) {
                                if viewModel.overviewData.isFlowSolarToBattery() {
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

                                if viewModel.overviewData.isFlowSolarToHouse() {
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

                                if viewModel.overviewData.isFlowGridToHouse() {
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
                                if viewModel.overviewData.currentBatteryLevel != nil {
                                    BatteryBoubleView(
                                        currentBatteryLevel: $viewModel.overviewData.currentBatteryLevel,
                                        currentChargeRate: $viewModel.overviewData.currentBatteryChargeRate
                                    )
                                } else {
                                    Text("")
                                        .frame(minWidth: 120, minHeight: 120)
                                }
                                
                                if viewModel.overviewData.isFlowBatteryToHome() {
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
                                    Image(systemName: "house")
                                }
                                .frame(maxWidth: 120, maxHeight: 120)
                            } // :GridRow
                            
                            GridRow {
                                
                                Text("")
                                
                                Text("")
                                
                                VStack {
                                    if viewModel.overviewData.isAnyCarCharing {
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
                                    
                                    ChargingStationsView(chargingStation: $viewModel.overviewData.chargingStations)
                                        .frame(maxWidth: 120)
                                }
                                
                            }
                            
                        } // :Grid
                        
                    } // :VStack
                    .padding(.top, 70)
                }  // :ZStack
            }
        }
        .onAppear {
            if viewModel.overviewData.lastSuccessServerFetch == nil {
                print("fetch on appear")
                Task {
                    await viewModel.fetchServerData()
                }
            }

            if refreshTimer == nil {
                refreshTimer = Timer.scheduledTimer(
                    withTimeInterval: 15, repeats: true
                ) {
                    _ in
                    Task {
                        print("fetch on timer")
                        await viewModel.fetchServerData()
                    }
                }  // :refreshTimer
            }  // :if
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(
            BuildingStateViewModel.fake(
                overviewData: OverviewData.fake()))
}
