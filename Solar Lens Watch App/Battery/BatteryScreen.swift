import Charts
import SwiftUI

struct BatteryScreen: View {
    @Environment(CurrentBuildingState.self) var model: CurrentBuildingState

    @State var isLoading = false

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

                    GeometryReader { geometry in

                        VStack(alignment: .leading) {

                            if !model.overviewData.isStaleData {

                                BatteryIndicator(
                                    percentage: Double(
                                        model.overviewData.currentBatteryLevel
                                            ?? 0
                                    ),
                                    showPercentage: true,
                                    height: 30,
                                    width: geometry.size.width
                                )

                                HStack {
                                    let charging =
                                        model.overviewData
                                        .currentBatteryChargeRate
                                        ?? 0

                                    if charging > 0 {
                                        HStack {
                                            Image(
                                                systemName:
                                                    "arrow.right.circle.fill"
                                            )
                                            .foregroundColor(.green)

                                            Text(
                                                "In:"
                                            )
                                            .foregroundColor(.green)

                                            Text(
                                                "\(model.overviewData.currentBatteryChargeRate ?? 0) W"
                                            )
                                        }.padding(.top)
                                    } else if charging < 0 {
                                        HStack {

                                            Image(
                                                systemName:
                                                    "arrow.left.circle.fill"
                                            )
                                            .foregroundColor(.orange)

                                            Text(
                                                "Out:"
                                            )
                                            .foregroundColor(.orange)

                                            Text(
                                                "\(model.overviewData.currentBatteryChargeRate ?? 0) W"
                                            )
                                        }.padding(.top)
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

                            Divider()
                                .padding(.vertical)

                            BatteryDevicesList(
                                batteryDevices: model.overviewData.devices
                                    .filter { $0.deviceType == .battery }
                            )

                        }  // :VStack
                    }  // :GeometryReader

                }  // :ScrollView
                .padding(.horizontal)
            }  // :ZStack
        }  // :if
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
                    devices: [],
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
                    devices: [],
                    todayAutarchyDegree: 78
                )
            )
        )
}
