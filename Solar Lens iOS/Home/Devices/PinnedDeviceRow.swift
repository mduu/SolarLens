import SwiftUI

struct PinnedDeviceRow: View {
    var device: Device
    @State private var isDeviceSheetShown: Bool = false
    @ObservedObject var pinnedConfig: PinnedDevicesConfiguration

    var body: some View {
        HStack(spacing: 12) {
            DeviceIconView(device: device)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if device.hasPower() {
                    Text(device.currentPowerInWatts.formatWattsAsWattsKiloWatts(widthUnit: true))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                } else {
                    Text(verbatim: "-")
                        .font(.subheadline)
                        .foregroundStyle(.primary.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
        .onTapGesture { isDeviceSheetShown = true }
        .sheet(isPresented: $isDeviceSheetShown) {
            NavigationView {
                DevicePrioritySheet(pinnedConfig: pinnedConfig)
            }
            .presentationDetents([.large])
        }
    }
}

#Preview {
    let config = PinnedDevicesConfiguration()
    VStack {
        PinnedDeviceRow(
            device: .init(
                id: "1",
                deviceType: .other,
                name: "Water Heater",
                priority: 1,
                currentPowerInWatts: 2340,
                signal: .connected
            ),
            pinnedConfig: config
        )
        PinnedDeviceRow(
            device: .init(
                id: "2",
                deviceType: .other,
                name: "Smart Plug",
                priority: 2,
                currentPowerInWatts: 450,
                signal: .connected
            ),
            pinnedConfig: config
        )
    }
    .padding()
}
