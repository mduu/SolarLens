import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: BuildingStateViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var refreshTimer: Timer?

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
                            .scaledToFill()
                            .saturation(0)
                            .opacity(colorScheme == .light ? 0.1 : 0.4)
                            .ignoresSafeArea()
                    }
                    

                    VStack {
                        Spacer()

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
                                    .foregroundColor(.white)
                                    .font(.system(size: 24, weight: .bold))

                            }

                        }  // :HStack

                    }  // :VStack

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
                        
                        let battery = viewModel.overviewData.currentBatteryLevel ?? 0
                        
                        Grid(horizontalSpacing: 2, verticalSpacing: 20) {
                            GridRow(alignment: .center) {
                                CircularInstrument(
                                    borderColor: Color.accentColor,
                                    label: "Solar Production",
                                    value: String(format: "%.1f kW", solar)
                                )
                                
                                if viewModel.overviewData.isFlowSolarToGrid() {
                                    Image(systemName: "arrow.right")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 50, weight: .heavy))
                                        .shadow(radius: 4, x: 4, y: 4)
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
                                )
                            }
                            
                            GridRow(alignment: .center) {
                                if viewModel.overviewData.isFlowSolarToBattery() {
                                    Image(systemName: "arrow.down")
                                        .foregroundColor(.green.opacity(0.9))
                                        .font(.system(size: 50, weight: .heavy))
                                        .shadow(radius: 4, x: 4, y: 4)
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
                                        .font(.system(size: 50, weight: .heavy))
                                        .shadow(radius: 4, x: 4, y: 4)
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
                                        .font(.system(size: 50, weight: .heavy))
                                        .shadow(radius: 4, x: 4, y: 4)
                                        .symbolEffect(
                                            .wiggle.byLayer,
                                            options: .repeat(.periodic(delay: 0.7)))
                                } else {
                                    Text("")
                                        .frame(minWidth: 50, minHeight: 50)
                                }
                            }.frame(minWidth: 30, minHeight: 20)
                            
                            GridRow(alignment: .center) {
                                if viewModel.overviewData.currentBatteryLevel != nil {
                                    CircularInstrument(
                                        borderColor: Color.green,
                                        label: "Battery",
                                        value: String(format: "%.0f %%", battery)
                                    )
                                } else {
                                    Text("")
                                        .frame(minWidth: 150, minHeight: 150)
                                }
                                
                                if viewModel.overviewData.isFlowBatteryToHome() {
                                    Image(systemName: "arrow.right")
                                        .foregroundColor(.green)
                                        .font(.system(size: 50, weight: .heavy))
                                        .shadow(radius: 4, x: 4, y: 4)
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
                                )
                            }
                            
                        }
                        
                    }  // :VStack
                    .padding(.top, 50)
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
