//

import SwiftUI

struct DevicePriorityRow: View {
    var device: Device

    var body: some View {
        HStack {
            DeviceIconView(device: device)
                .frame(minWidth: 30)

            Text(device.name)
                .fontWeight(.semibold)

            Spacer()
            
            let text =
                device.hasPower()
                ? String(
                    format: "%.2f kW",
                    Double(device.currentPowerInWatts) / 1000
                )
                : ""
            
            Text(text)
                .font(.caption)
                .padding(.trailing, 4)
            
            DeviceConnectionIndicator(device: device)
                .padding(.trailing, 4)

            Image(systemName: "line.3.horizontal")  // Drag handle icon
                .foregroundColor(.teal)
        }
    }
}

#Preview {

    VStack {
        DevicePriorityRow(
            device: .init(
                id: "1",
                deviceType: .battery,
                name: "Battery",
                priority: 1,
                currentPowerInWatts: 1234,
                color: "#FF00FF",
                signal: .connected,
                hasError: false
            )
        )
        .padding(.horizontal, 30)
        .padding(.vertical, 10)

        DevicePriorityRow(
            device: .init(
                id: "1",
                deviceType: .carCharging,
                name: "Charging Station",
                priority: 1,
                currentPowerInWatts: 1234,
                color: "#FF00FF",
                signal: .notConnected,
                hasError: true
            )
        )
        .padding(.horizontal, 30)

        Spacer()
    }
}
