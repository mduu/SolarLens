import SwiftUI

enum PercentageField: Hashable {
    case minPercentage
    case morningPercentage
    case maxPercentage
    case none  // No field is specifically focused
}

struct ModeEcoOptions: View {
    var battery: Device

    @Environment(CurrentBuildingState.self) var model: CurrentBuildingState

    @Binding var minPercentage: Int
    @Binding var morningPercentage: Int
    @Binding var maxPercentage: Int

    var body: some View {
        Grid(
            alignment: .leadingFirstTextBaseline,
            verticalSpacing: 3
        ) {

            GridRow {
                Text("Min.:")
                Spacer()
                PercentagePicker(
                    value: $minPercentage,
                    tintColor: .purple
                )
            }

            GridRow {
                Text("Morning:")
                Spacer()
                PercentagePicker(
                    value: $morningPercentage,
                    tintColor: .purple
                )
            }

            GridRow {
                Text("Max.:")
                Spacer()
                PercentagePicker(
                    value: $maxPercentage,
                    tintColor: .purple
                )
            }
        }  // :Grid

        VStack(alignment: .leading) {
            Text("Info:")
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundColor(.purple)

            Text(
                "Battery will be charged to the 'Morning' level in the morning. Then other devices can be charged. The battery will be charged to 'Max' until the eventing."
            )
            .font(.footnote)

        }

        Spacer()

    }
}

#Preview {
    ModeEcoOptions(
        battery: .fakeBattery()
    )
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
