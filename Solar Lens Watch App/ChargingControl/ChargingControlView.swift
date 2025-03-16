import SwiftUI

struct ChargingControlView: View {
    @Environment(CurrentBuildingState.self) var model: CurrentBuildingState

    @State var newCarCharging: ControlCarChargingRequest? = nil
    @State var showChargingModeConfig: Bool = false
    @State var chargingConfiguration = ChargingModeConfiguration()

    var body: some View {
        ZStack {

            LinearGradient(
                gradient: Gradient(colors: [
                    .green.opacity(0.5), .green.opacity(0.2),
                ]), startPoint: .top, endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack {

                    VStack {
                        ChargingInfo(
                            totalChargedToday: .constant(
                                model.chargingInfos?.totalCharedToday),
                            currentChargingPower: .constant(
                                model.chargingInfos?.currentCharging)
                        )
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 10)
                    .onTapGesture {
                        Task {
                            await model.fetchChargingInfos()
                        }
                    }

                    VStack(spacing: 10) {
                        ForEach(model.overviewData.chargingStations, id: \.id) {
                            chargingStation in

                            VStack(alignment: .leading, spacing: 3) {
                                ChargingStationModeView(
                                    isTheOnlyOne: model.overviewData
                                        .chargingStations
                                        .count
                                        <= 1,
                                    chargingStation: chargingStation,
                                    chargingModeConfiguration:
                                        chargingConfiguration)
                            }  // :VStack
                        }  // :ForEach

                        HStack {
                            Spacer()

                            Button(action: {
                                showChargingModeConfig = true
                                model.pauseFetching()
                            }) {
                                Image(systemName: "gear")
                            }
                            .buttonStyle(.borderless)
                            .foregroundColor(.secondary)
                            .padding(.trailing, 15)
                            .sheet(isPresented: $showChargingModeConfig) {
                                ChargingModeConfigurationView(
                                    chargingModeConfiguration:
                                        chargingConfiguration
                                )
                                .onDisappear {
                                    model.resumeFetching()
                                }

                            }  // :Sheet
                        }  // :HStack
                    }  // :VStack
                }  // :VStack
            }  // :ScrollView

            if model.isChangingCarCharger {
                HStack {
                    ProgressView()
                }  // :HStack
                .background(Color.black.opacity(0.8))
            }
        }  // :ZStack
        .onAppear {
            Task {
                await model.fetchChargingInfos()
            }
        }
    }  // :Body
}  // :View

#Preview {
    ChargingControlView()
        .environment(
            CurrentBuildingState.fake(
                overviewData: .init(
                    currentSolarProduction: 4550,
                    currentOverallConsumption: 1200,
                    currentBatteryLevel: 78,
                    currentBatteryChargeRate: 3400,
                    currentSolarToGrid: 10,
                    currentGridToHouse: 0,
                    currentSolarToHouse: 1200,
                    solarProductionMax: 11000,
                    hasConnectionError: false,
                    lastUpdated: Date(),
                    lastSuccessServerFetch: Date(),
                    isAnyCarCharing: false,
                    chargingStations: [
                        .init(
                            id: "42",
                            name: "Keba",
                            chargingMode: ChargingMode.withSolarPower,
                            priority: 1,
                            currentPower: 0,
                            signal: SensorConnectionStatus.connected)
                    ],
                    devices: []
                )
            ))
}
