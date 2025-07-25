import SwiftUI

struct BatteryModeSheet: View {
    let battery: Device

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {

                if battery.batteryInfo?.modeInfo.batteryMode == .Standard {
                    BatteryModeButton(
                        battery: battery,
                        mode: BatteryMode.Standard
                    )
                    .disabled(true)
                } else {

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

                    /*
                     BatteryModeButton(
                     battery: battery,
                     mode: BatteryMode.TariffOptimized
                     )
                     */

                }
            }  // :VStack

        }  // :ScrollView
    }

}

#Preview {
    BatteryModeSheet(
        battery: Device.fakeBattery()
    )
}
