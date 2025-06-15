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

            #if os(watchOS)
            
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
            
            #else
            
            Grid(
                alignment: .leadingLastTextBaseline,
                verticalSpacing: 3
            ) {

                GridRow {
                    Text("Discharging limit:")
                    IntPicker(
                        value: $socDischargeLimit,
                        step: 1,
                        tintColor: .purple
                    )
                }
                .padding(.top, 4)

                GridRow {
                    Text("Charging limit:")
                    IntPicker(
                        value: $socMaxLimit,
                        tintColor: .purple
                    )
                }
                .padding(.top, 4)

                GridRow {
                    Text("Max. Grid Power:")
                    IntPicker(
                        value: $maxGridPower,
                        step: 500,
                        max: 25000,
                        tintColor: .purple,
                        unit: "W"
                    )
                }
                .padding(.top, 4)

                GridRow {
                    Text("Recharging limit:")
                    IntPicker(
                        value: $rechargePower,
                        step: 500,
                        max: 25000,
                        tintColor: .purple,
                        unit: "W"
                    )

                }
                .padding(.top, 4)

            }  // :Grid
            #endif

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
}

#Preview {
    ScrollView {
        PeakShavingOptionsView(
            battery: .fakeBattery(),
            socDischargeLimit: .constant(10),
            socMaxLimit: .constant(40),
            maxGridPower: .constant(10),
            rechargePower: .constant(5)
        )
        .environment(
            CurrentBuildingState.fake(
                overviewData: OverviewData.fakeWithBattery()
            )
        )
    }
}
