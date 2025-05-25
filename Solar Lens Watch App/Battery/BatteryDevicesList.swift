// 

import SwiftUI

struct BatteryDevicesList: View {
    let batteryDevices: [Device]
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(batteryDevices) { battery in
                if batteryDevices.count > 1 {
                    Text("Bat. \(battery.name)")
                        .fontWeight(.bold)
                        .foregroundColor(.purple.opacity(0.9))
                    BatteryModeView(
                        battery: battery
                    )
                }
            }
        }
    }
}

#Preview("1 Battery") {
    BatteryDevicesList(
        batteryDevices: [
            Device(
                id: "1234",
                deviceType: .battery,
                name: "Test 1",
                priority: 1
            )
        ]
    )
}

#Preview("2 Batteries") {
    BatteryDevicesList(
        batteryDevices: [
            Device(
                id: "1234",
                deviceType: .battery,
                name: "Test 1",
                priority: 1
            ),
            Device(
                id: "222",
                deviceType: .battery,
                name: "Test 2",
                priority: 2
            )
        ]
    )
}
