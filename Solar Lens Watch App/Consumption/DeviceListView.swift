import SwiftUI

struct DeviceListView: View {
    var devices: [Device]

    var body: some View {
        VStack(alignment: .leading) {

            Text("Devices")
                .font(.headline)
                .foregroundColor(.cyan)

            ForEach(devices.sorted(by: { $0.priority < $1.priority })) {
                device in
                DeviceItemView(device: device)
            }
        }
    }
}

#Preview {
    DeviceListView(
        devices: [
            Device.init(
                id: "1", deviceType: .Battery, name: "Battery", priority: 1,
                currentPowerInWatts: 4500),
            Device.init(
                id: "2", deviceType: .CarCharging, name: "Charging #1",
                priority: 2),
            Device.init(
                id: "3", deviceType: .EnergyMeasurement, name: "Home-Office",
                priority: 3),
        ]
    )
}
