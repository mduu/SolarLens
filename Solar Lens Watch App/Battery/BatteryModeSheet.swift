import SwiftUI

struct BatteryModeSheet: View {
    let battery: Device

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {

                if battery.batteryInfo?.batteryMode == .Standard {
                    BatteryModeButton(
                        battery: battery,
                        mode: BatteryMode.Standard
                    )
                }

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
    }

}

#Preview {
    BatteryModeSheet(
        battery: Device.fakeBattery()
    )
}
