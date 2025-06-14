import SwiftUI

struct BatteryModeButton: View {
    let battery: Device
    let mode: BatteryMode

    @State var showBatteryModeOptions = false

    var body: some View {
        let isActiveButton = battery.batteryInfo?.modeInfo.batteryMode == mode
        let modeName = mode.GetBatteryModeName()

        Button(action: {
            showBatteryModeOptions = true
        }) {
            HStack(alignment: .top) {
                if isActiveButton {
                    Image(systemName: "checkmark.circle.fill")
                }

                Text(modeName)
                    .font(.headline)
                    .lineLimit(2)
            }
        }
        .buttonStyle(.borderedProminent)
        .frame(maxWidth: .infinity)
        .tint(
            isActiveButton ? .purple.opacity(0.6) : .white.opacity(0.3)
        )
        .sheet(
            isPresented: $showBatteryModeOptions) {
            BatteryModeOptionsSheet(
                battery: battery,
                targetMode: mode
            )
        }
    }
}

#Preview {
    BatteryModeButton(
        battery: .fakeBattery(),
        mode: .Eco
    )
}
