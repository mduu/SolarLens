import SwiftUI

struct DeviceItemView: View {
    var device: Device
    
    var body: some View {
        HStack {
            Text(device.name).foregroundColor(.primary)
            
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
                    systemName: device.priority > 1
                        ? "arrow.up.circle"
                        : "arrow.down.circle"
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

#Preview("First") {
    VStack {
        DeviceItemView(
            device: .init(
                id: "1",
                deviceType: .Battery,
                name: "Battery",
                priority: 1,
                currentPowerInWatts: 0)
        )
    }.background(Color.cyan.opacity(0.1))
        .frame(maxHeight: 60)
}

#Preview("Other") {
    VStack {
        DeviceItemView(
            device: .init(
                id: "2",
                deviceType: .Battery,
                name: "Battery",
                priority: 2,
                currentPowerInWatts: 0)
        )
    }.background(Color.cyan.opacity(0.1))
        .frame(maxHeight: 60)
}

