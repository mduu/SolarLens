import Charts
import SwiftUI

struct BatteryScreen: View {
    @Environment(CurrentBuildingState.self) var model: CurrentBuildingState

    @State var isLoading = false
    @State private var mainData: MainData?
    @State private var tariff: TariffV1Response?
    @State private var showBatteryChart = false

    var body: some View {
        if model.overviewData.currentBatteryLevel != nil
            || model.overviewData.currentBatteryChargeRate != nil
        {

            ZStack {

                LinearGradient(
                    gradient: Gradient(colors: [
                        .purple.opacity(0.4), .purple.opacity(0.1),
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)

                ScrollView {

                    VStack(alignment: .leading, spacing: 8) {

                        if !model.overviewData.isStaleData {
                            HStack {
                                WatchBatteryStatusView(
                                    level: model.overviewData.currentBatteryLevel ?? 0,
                                    charging: model.overviewData.currentBatteryChargeRate ?? 0
                                )

                                RoundChartButton {
                                    model.pauseFetching()
                                    withAnimation {
                                        showBatteryChart = true
                                    }
                                }
                            }
                        } else {
                            Text("No current data")
                                .foregroundStyle(.red)
                        }

                        BatteryForecastView(
                            batteryForecast: model.overviewData
                                .getBatteryForecast()
                        )

                        if model.overviewData.hasAnyBattery {
                            WatchBatteryAdvantageView(
                                mainData: mainData,
                                tariff: tariff,
                                todayConsumption: model.overviewData.todayConsumption ?? 0,
                                todayProduction: model.overviewData.todayProduction ?? 0,
                                autarkyWithBattery: model.overviewData.todayAutarchyDegree ?? 0,
                                selfConsumptionWithBattery: model.overviewData.todaySelfConsumptionRate ?? 0
                            )
                        }

                        BatteryDevicesList(
                            batteryDevices: model.overviewData.devices
                                .filter { $0.deviceType == .battery }
                        )
                        .padding(.top, 4)
                        .frame(maxWidth: .infinity)

                    }  // :VStack

                }  // :ScrollView
                .padding(.horizontal)

            }  // :ZStack
            .task {
                await fetchData()
            }
            .sheet(isPresented: $showBatteryChart) {
                BatteryChartSheet()
                    .navigationTitle("Battery")
                    .onDisappear {
                        model.resumeFetching()
                    }
            }
        }  // :if
    }

    // MARK: - Data Fetching

    private func fetchData() async {
        let manager = SolarManager.shared

        async let mainDataTask = try? manager.fetchMainData(
            from: Date.todayStartOfDay(),
            to: Date.todayEndOfDay()
        )
        async let tariffTask = try? manager.fetchTariff()

        let (fetchedMainData, fetchedTariff) = await (mainDataTask, tariffTask)
        self.mainData = fetchedMainData
        self.tariff = fetchedTariff
    }
}

#Preview("Charging") {
    BatteryScreen()
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
                            signal: SensorConnectionStatus.connected
                        )
                    ],
                    devices: [
                        Device.fakeBattery(currentPowerInWatts: 2390)
                    ],
                    todayAutarchyDegree: 78
                )
            )
        )
}

#Preview("Discharging") {
    BatteryScreen()
        .environment(
            CurrentBuildingState.fake(
                overviewData: .init(
                    currentSolarProduction: 4550,
                    currentOverallConsumption: 1200,
                    currentBatteryLevel: 20,
                    currentBatteryChargeRate: -800,
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
                            signal: SensorConnectionStatus.connected
                        )
                    ],
                    devices: [
                        Device.fakeBattery(currentPowerInWatts: -2390)
                    ],
                    todayAutarchyDegree: 78
                )
            )
        )
}
