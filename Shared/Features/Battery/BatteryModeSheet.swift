import SwiftUI

struct BatteryModeSheet: View {
    let battery: Device

    var body: some View {
        ScrollView {
            if battery.batteryInfo?.modeInfo.batteryMode == .Standard {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ], spacing: 10) {
                    BatteryModeButton(
                        battery: battery,
                        mode: BatteryMode.Standard
                    )
                    .disabled(true)
                }
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ], spacing: 10) {
                    BatteryModeButton(
                        battery: battery,
                        mode: BatteryMode.StandardControlled
                    )

                    BatteryModeButton(
                        battery: battery,
                        mode: BatteryMode.Eco
                    )

                    BatteryModeButton(
                        battery: battery,
                        mode: BatteryMode.PeakShaving
                    )

                    BatteryModeButton(
                        battery: battery,
                        mode: BatteryMode.Manual
                    )
                }
            }
        }  // :ScrollView
    }

}

#Preview {
    BatteryModeSheet(
        battery: Device.fakeBattery()
    )
}
