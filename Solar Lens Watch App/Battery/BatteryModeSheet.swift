import SwiftUI

struct BatteryModeSheet: View {
    let battery: Device

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {

                if battery.batteryInfo?.batteryMode == .Standard {
                    ModePanel(
                        mode: BatteryMode.Standard,
                        modeName: "Standard",
                    )
                }
                
                ModePanel(
                    mode: BatteryMode.StandardControlled,
                    modeName: "Standard",
                )

                ModePanel(
                    mode: BatteryMode.Eco,
                    modeName: "Eco",
                )

                ModePanel(
                    mode: BatteryMode.PeakShaving,
                    modeName: "Peak shaving",
                )

                ModePanel(
                    mode: BatteryMode.Manual,
                    modeName: "Manual",
                )
            }
        }
    }

    @ViewBuilder
    func ModePanel(
        mode: BatteryMode,
        modeName: LocalizedStringResource,
    ) -> some View {
        let isActiveButton = battery.batteryInfo?.batteryMode == mode

        Button(action: {
            // Action
        }) {
            HStack(alignment: .top) {
                Text(modeName)
                    .font(.headline)
                    .lineLimit(2)
            }
        }
        .buttonStyle(.borderedProminent)
        .frame(maxWidth: .infinity)
        .tint(
            isActiveButton ? .purple.opacity(0.4) : .white.opacity(0.3)
        )
    }
}

#Preview {
    BatteryModeSheet(
        battery: Device.fakeBattery()
    )
}
