import SwiftUI

struct DeviceItemView: View {
    var device: Device

    var body: some View {
        HStack {
            VStack {
                HStack {
                    Text(device.name).foregroundColor(.primary)
                    
                    Spacer()
                }  // :HStack
                
                HStack {
                    if device.hasPower() {
                        Text(
                            String(
                                format: "%.2f kW",
                                Double(device.currentPowerInWatts) / 1000)
                        )
                        .foregroundColor(.cyan)
                        .font(.footnote)
                    }
                    
                    Spacer()
                }
                
            }  // :VStack
            
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
            
        } // :HStack
        .frame(minHeight: 50)
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
                currentPowerInWatts: -540)
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
