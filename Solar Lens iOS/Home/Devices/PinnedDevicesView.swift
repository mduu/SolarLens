import SwiftUI

struct PinnedDevicesView: View {
    @Environment(CurrentBuildingState.self) var buildingState: CurrentBuildingState
    @ObservedObject var pinnedConfig: PinnedDevicesConfiguration

    var pinnedDevices: [Device] {
        buildingState.overviewData.devices
            .filter { device in
                device.deviceType != .battery
                    && device.deviceType != .carCharging
                    && pinnedConfig.isPinned(deviceId: device.id)
            }
            .sorted(by: { $0.priority < $1.priority })
    }

    var body: some View {
        if !pinnedDevices.isEmpty {
            VStack(spacing: 8) {
                ForEach(pinnedDevices) { device in
                    PinnedDeviceRow(device: device, pinnedConfig: pinnedConfig)
                }
            }
        }
    }
}
