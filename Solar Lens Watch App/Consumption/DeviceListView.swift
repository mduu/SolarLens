import SwiftUI

struct DeviceListView: View {
    var devices: [Device]

    var body: some View {
        ScrollView {
            ForEach(devices.sorted(by: {$0.priority < $1.priority})) { device in
                    
                HStack {
                    Text(device.name)
                    
                    Spacer()
                    
                    if device.hasPower() {
                        Text(
                            String(
                                format: "%.2f kW",
                                Double(device.currentPowerInWatts) / 1000)
                        )
                        .foregroundColor(.cyan)
                        .font(.footnote)
                    }
                    
                    Button(action: {
                        // TODO Add action code
                    }) {
                        Image(
                            systemName: "arrow.up.circle"
                        )
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25, height: 25)
                    }
                    .buttonStyle(.borderless)
                    .buttonBorderShape(.circle)
                    .foregroundColor(.primary)
                }
                .frame(minHeight:40)
                .padding(3)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(.cyan.opacity(0.1))
                )
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
