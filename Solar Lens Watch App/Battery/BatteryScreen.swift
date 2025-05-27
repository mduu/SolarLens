import Charts
import SwiftUI

struct BatteryScreen: View {
    @Environment(CurrentBuildingState.self) var model: CurrentBuildingState

    @State var isLoading = false

    private let positionalFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated  // e.g., "01:01:05" or "01:05"
        formatter.allowedUnits = [.hour, .minute]
        formatter.zeroFormattingBehavior = .pad
        formatter.collapsesLargestUnit = true  // If hours are 0, it collapses to minutes and seconds
        return formatter
    }()

    var body: some View {

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
                                    model.overviewData.currentBatteryLevel ?? 0
                                ),
                                showPercentage: true,
                                height: 30,
                                width: geometry.size.width - 10
                            )

                            HStack {
                                let charging =
                                    model.overviewData.currentBatteryChargeRate
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
                                            systemName: "arrow.left.circle.fill"
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
                        
                        HStack {
                            Text("Mode:")
                            Button(action: {
                                // Action
                            }) {
                                Text("Standard")
                            }
                            .buttonBorderShape(.circle)
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                        }
                        .padding(.top)

                        let batteryForecast = model.overviewData
                            .getBatteryForecast()

                        if let batteryForecast {
                            
                            if batteryForecast.durationUntilDischarged != nil
                                && batteryForecast.timeWhenDischarged != nil
                            {
                                Divider()
                                    .padding()

                                HStack {
                                    Image(systemName: "battery.0percent")
                                        .foregroundColor(.red)
                                        .rotationEffect(.degrees(-90))
                                    
                                    VStack(alignment: .leading) {
                                        Text(
                                            "Empty in \(positionalFormatter.string(from: batteryForecast.durationUntilDischarged!) ?? "") at \(batteryForecast.timeWhenDischarged!.formatted(date: .omitted, time: .shortened))"
                                        )
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(2)
                                        .frame(minHeight: 40)
                                    }
                                }
                            }

                            if batteryForecast.durationUntilFullyCharged != nil
                            {
                                Divider()
                                    .padding()

                                HStack {
                                    Image(systemName: "battery.100percent")
                                        .foregroundColor(.green)
                                        .rotationEffect(.degrees(-90))

                                    VStack(alignment: .leading) {
                                        Text(
                                            "Full in \(positionalFormatter.string(from: batteryForecast.durationUntilFullyCharged!) ?? "") at \(batteryForecast.timeWhenFullyCharged!.formatted(date: .omitted, time: .shortened))"
                                        )
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(2)
                                        .frame(minHeight: 40)
                                    }
                                }
                            }
                        }

                        /*
                        let batteries = model.overviewData.devices
                            .filter { $0.deviceType == .battery }
                        
                        BatteryDevicesList(batteryDevices: batteries)
                         */

                    }  // :VStack
                }  // :GeometryReader

            }  // :ScrollView
            .padding(.horizontal)
        }  // :ZStack
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
