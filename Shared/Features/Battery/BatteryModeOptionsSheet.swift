//

import SwiftUI

struct BatteryModeOptionsSheet: View {
    var battery: Device
    var targetMode: BatteryMode

    var body: some View {
        VStack(alignment: .leading) {
            Text(
                "Set '\(battery.name)' to '\(targetMode.GetBatteryModeName())'."
            )

            switch targetMode {
            case .Standard:
                Text("To implement")
                
            case .Eco:
                ModeEcoOptions(battery: battery)
                
            case .PeakShaving:
                Text("To implement")

            case .TariffOptimized:
                Text("To implement")
                
            case .Manual:
                Text("To implement")
                
            case .StandardControlled:
                Text("To implement")
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    Text("Battery options")
                        .foregroundColor(.purple)
                        .font(.headline)
                }
            }  // :ToolbarItem
        }  // :.toolbar
    }
}

#Preview("Standard Controlled") {
    BatteryModeOptionsSheet(
        battery: Device.fakeBattery(),
        targetMode: .StandardControlled
    )
}

#Preview("Standard") {
    BatteryModeOptionsSheet(
        battery: Device.fakeBattery(),
        targetMode: .Standard
    )
}

#Preview("Eco") {
    BatteryModeOptionsSheet(
        battery: Device.fakeBattery(),
        targetMode: .Eco
    )
}

#Preview("Peak sh.") {
    BatteryModeOptionsSheet(
        battery: Device.fakeBattery(),
        targetMode: .PeakShaving
    )
}

#Preview("Manual") {
    BatteryModeOptionsSheet(
        battery: Device.fakeBattery(),
        targetMode: .Manual
    )
}

#Preview("Tariff") {
    BatteryModeOptionsSheet(
        battery: Device.fakeBattery(),
        targetMode: .TariffOptimized
    )
}
