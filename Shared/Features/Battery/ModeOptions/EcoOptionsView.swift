import SwiftUI

struct EcoOptionsView: View {
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
                IntPicker(
                    value: $minPercentage,
                    step: 1,
                    tintColor: .purple
                )
            }

            GridRow {
                Text("Morning:")
                Spacer()
                IntPicker(
                    value: $morningPercentage,
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
    EcoOptionsView(
        battery: .fakeBattery(),
        minPercentage: .constant(5),
        morningPercentage: .constant(80),
        maxPercentage: .constant(100)
    )
    .environment(
        CurrentBuildingState.fake(
            overviewData: OverviewData.fakeWithBattery()
        )
    )
}
