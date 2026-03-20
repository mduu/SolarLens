//

import SwiftUI

struct DevicePriorityRow: View {
    var device: Device
    @ObservedObject var pinnedConfig: PinnedDevicesConfiguration

    private var canPin: Bool {
        device.deviceType != .battery && device.deviceType != .carCharging
    }

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

            if canPin {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        pinnedConfig.togglePin(deviceId: device.id)
                    }
                } label: {
                    Image(systemName: pinnedConfig.isPinned(deviceId: device.id) ? "pin.fill" : "pin")
                        .font(.caption)
                        .foregroundColor(pinnedConfig.isPinned(deviceId: device.id) ? .teal : .gray.opacity(0.4))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)
            }

            DeviceConnectionIndicator(device: device)
                .padding(.trailing, 4)

            Image(systemName: "line.3.horizontal")
                .font(.caption)
                .foregroundStyle(.tertiary)
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
            ),
            pinnedConfig: PinnedDevicesConfiguration()
        )
        .padding(.horizontal, 30)
        .padding(.vertical, 10)

        DevicePriorityRow(
            device: .init(
                id: "2",
                deviceType: .other,
                name: "Water Heater",
                priority: 2,
                currentPowerInWatts: 1234,
                color: "#FF00FF",
                signal: .connected,
                hasError: false
            ),
            pinnedConfig: PinnedDevicesConfiguration()
        )
        .padding(.horizontal, 30)

        Spacer()
    }
}
