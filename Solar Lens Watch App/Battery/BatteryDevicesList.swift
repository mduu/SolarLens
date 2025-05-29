// 

import SwiftUI

struct BatteryDevicesList: View {
    let batteryDevices: [Device]
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(batteryDevices) { battery in
                BatteryView(
                    battery: battery
                )
            }
        }
    }
}

#Preview("1 Battery") {
    BatteryDevicesList(
        batteryDevices: [
            Device.fakeBattery(
                id: "1",
                name: "Bat 1",
                priority: 0,
                currentPowerInWatts: 3600
            ),
        ]
    )
}

#Preview("2 Batteries") {
    BatteryDevicesList(
        batteryDevices: [
            Device.fakeBattery(
                id: "0",
                name: "Bat 1",
                priority: 0,
                currentPowerInWatts: 3600
            ),
            Device.fakeBattery(
                id: "1",
                name: "Bat 2",
                priority: 1,
                currentPowerInWatts: 1200
            ),
        ]
    )
}
