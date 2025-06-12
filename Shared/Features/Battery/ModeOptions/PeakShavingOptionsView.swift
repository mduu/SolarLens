//

import SwiftUI

struct PeakShavingOptionsView: View {
    var battery: Device

    @Environment(CurrentBuildingState.self) var model: CurrentBuildingState

    @Binding var socDischargeLimit: Int
    @Binding var socMaxLimit: Int
    @Binding var maxGridPower: Int
    @Binding var rechargePower: Int

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 3
        ) {

            Text("Min. discharging limit:")
                .padding(.top, 4)
            IntPicker(
                value: $socDischargeLimit,
                step: 1,
                tintColor: .purple
            )

            Text("Max. charging limit:")
                .padding(.top, 12)
            IntPicker(
                value: $socMaxLimit,
                tintColor: .purple
            )

            Text("Max. Grid Power:")
                .padding(.top, 12)
            IntPicker(
                value: $maxGridPower,
                step: 500,
                max: 25000,
                tintColor: .purple,
                unit: "W"
            )
            
            Text("Recharging limit:")
                .padding(.top, 12)
            IntPicker(
                value: $rechargePower,
                step: 500,
                max: 25000,
                tintColor: .purple,
                unit: "W"
            )

        }  // :Grid

        VStack(alignment: .leading) {
            Text("Info:")
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundColor(.purple)

            Text(
                "'Peak Shaving' uses your battery to supply power during high-demand periods, reducing the amount of expensive electricity drawn from the grid and lowering your overall costs."
            )
            .font(.footnote)
            .frame(maxWidth: .infinity, maxHeight: 200)

        }

        Spacer()
    }
}

#Preview {
    PeakShavingOptionsView(
        battery: .fakeBattery(),
        socDischargeLimit: .constant(10),
        socMaxLimit: .constant(40),
        maxGridPower: .constant(10),
        rechargePower: .constant(5)
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
