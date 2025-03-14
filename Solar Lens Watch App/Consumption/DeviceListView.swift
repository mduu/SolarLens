import SwiftUI

struct DeviceListView: View {
    var devices: [Device]
    var onSetNewPriority: (_ deviceId: String, _ newPriority: Int) -> Void

    var body: some View {
        VStack(alignment: .leading) {

            HStack {
                Text("Devices")
                    .font(.headline)
                    .foregroundColor(.cyan)

                Spacer()

                Text("Prio.")
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            ForEach(devices.sorted(by: { $0.priority < $1.priority })) {
                device in
                DeviceItemView(device: device) { deviceId, newPriority in
                    self.onSetNewPriority(deviceId, newPriority)
                }
            }
        }
    }
}

#Preview {
    DeviceListView(
        devices: [
            Device.init(
                id: "1", deviceType: .battery, name: "Battery", priority: 1,
                currentPowerInWatts: 4500),
            Device.init(
                id: "2", deviceType: .carCharging, name: "Charging #1",
                priority: 2),
            Device.init(
                id: "3", deviceType: .energyMeasurement, name: "Home-Office",
                priority: 3),
        ]
    ) { deviceId, newPriority in
    }
}
