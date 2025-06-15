import SwiftUI

struct ManualOptionsView: View {
    var battery: Device

    @Environment(CurrentBuildingState.self) var model: CurrentBuildingState

    @Binding var manualMode: BatteryManualMode
    @Binding var upperSocLimit: Int
    @Binding var lowerSocLimit: Int
    @Binding var powerCharge: Int
    @Binding var powerDischarge: Int

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 3
        ) {
            Text("Mode:")
            Picker("Mode", selection: $manualMode) {
                ForEach(BatteryManualMode.allCases) { mode in
                    Text(mode.localizedName)
                        .tag(mode)
                }
            }
            .labelsHidden()
            #if os(watchOS)
                .pickerStyle(.inline)
                .defaultWheelPickerItemHeight(30)
            #else
                .pickerStyle(.segmented)
            #endif
            .frame(minHeight: 60)

            #if os(watchOS)

                Text("Min. discharge limit:")
                    .padding(.top, 4)
                IntPicker(
                    value: $lowerSocLimit,
                    step: 1,
                    tintColor: .purple
                )

                Text("Max. charging limit:")
                    .padding(.top, 4)
                IntPicker(
                    value: $upperSocLimit,
                    tintColor: .purple
                )

                Text("Charging power:")
                    .padding(.top, 4)
                IntPicker(
                    value: $powerCharge,
                    step: 500,
                    min: 0,
                    max: battery.batteryInfo?.maxChargePower ?? 0,
                    tintColor: .purple,
                    unit: "W",
                )

                Text("Discharging power:")
                    .padding(.top, 4)
                IntPicker(
                    value: $powerDischarge,
                    step: 500,
                    min: 0,
                    max: battery.batteryInfo?.maxDischargePower ?? 0,
                    tintColor: .purple,
                    unit: "W",
                )

            #else

                Grid(
                    alignment: .leadingLastTextBaseline,
                    verticalSpacing: 3
                ) {

                    GridRow {
                        Text("Discharge limit:")
                        IntPicker(
                            value: $lowerSocLimit,
                            step: 1,
                            tintColor: .purple
                        )
                    }
                    .padding(.top, 4)

                    GridRow {
                        Text("Charging limit:")
                        IntPicker(
                            value: $upperSocLimit,
                            tintColor: .purple
                        )
                    }
                    .padding(.top, 4)

                    GridRow {
                        Text("Charging:")
                        IntPicker(
                            value: $powerCharge,
                            step: 500,
                            min: 0,
                            max: battery.batteryInfo?.maxChargePower ?? 0,
                            tintColor: .purple,
                            unit: "W",
                        )
                    }
                    .padding(.top, 4)

                    GridRow {
                        Text("Discharging:")
                        IntPicker(
                            value: $powerDischarge,
                            step: 500,
                            min: 0,
                            max: battery.batteryInfo?.maxDischargePower ?? 0,
                            tintColor: .purple,
                            unit: "W",
                        )

                    }
                    .padding(.top, 4)
                }

            #endif

            VStack(alignment: .leading) {
                Text("Info:")
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)

                Text(
                    "Contorl manually if the battery is charging, discharing or switched off."
                )
                .font(.footnote)
            }

        }  // :VStack

        Spacer()

    }
}

#Preview {
    ScrollView {
        ManualOptionsView(
            battery: .fakeBattery(),
            manualMode: .constant(.Charge),
            upperSocLimit: .constant(15),
            lowerSocLimit: .constant(95),
            powerCharge: .constant(100),
            powerDischarge: .constant(100)
        )
        .environment(
            CurrentBuildingState.fake(
                overviewData: OverviewData.fakeWithBattery()
            )
        )
    }
}
