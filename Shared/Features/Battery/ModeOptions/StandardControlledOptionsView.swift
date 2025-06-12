// 

import SwiftUI

struct StandardControlledOptionsView: View {
    var battery: Device

    @Environment(CurrentBuildingState.self) var model: CurrentBuildingState

    @Binding var allowStandalone: Bool
    @Binding var minPercentage: Int
    @Binding var maxPercentage: Int

    var body: some View {
        Grid(
            alignment: .leadingFirstTextBaseline,
            verticalSpacing: 5
        ) {
            
            GridRow {
                Toggle(isOn: $allowStandalone, label: { Text("Allow standalone") })
                    .gridCellColumns(3)
                    .padding(.bottom, 5)
            }

            GridRow {
                Text("Min.:")
                Spacer()
                IntPicker(
                    value: $minPercentage,
                    step: 1,
                    tintColor: .purple
                )
            }

            GridRow {
                Text("Max.:")
                Spacer()
                IntPicker(
                    value: $maxPercentage,
                    tintColor: .purple
                )
            }
        }  // :Grid

        VStack(alignment: .leading) {
            HStack {
                Text("Info:")
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                
                Spacer()
            }

            Text(
                "The battery will operate in standalone mode (if a smart meter is present) or controlled by Solar Manager with min/max percentage settings."
            )
            .font(.footnote)
            
            Text(
                "To let Solar Manager control the battery disable 'Allow standalone'."
            )
            .font(.footnote)
            .padding(.top, 2)

        }
        .frame(maxWidth: .infinity)

        Spacer()
    }
}

#Preview {
    StandardControlledOptionsView(
        battery: .fakeBattery(),
        allowStandalone: .constant(true),
        minPercentage: .constant(5),
        maxPercentage: .constant(100)
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
