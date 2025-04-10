import SwiftUI

struct DeviceRow: View {
    var device: Device
    var onSetNewPriority: (_ deviceId: String, _ newPriority: Int) -> Void

    var body: some View {
        HStack {
            VStack(alignment: .center) {
                DeviceIconView(device: device)
            }
            .frame(minWidth: 30)
            .frame(maxWidth: 30)
            .frame(width: 30)
            .scaledToFit()

            VStack(alignment: .leading) {
                HStack {
                    Text(device.name).foregroundColor(.primary)

                    Spacer()
                }  // :HStack

                HStack {
                    let text =
                        device.hasPower()
                        ? String(
                            format: "%.2f kW",
                            Double(device.currentPowerInWatts) / 1000)
                        : ""

                    Text(text)
                        .foregroundColor(.cyan)
                        .font(.footnote)

                    Spacer()
                }

            }  // :VStack
            .padding(.trailing, 4)

            Button(action: {
                let newPriortiy =
                    device.priority == 1
                    ? device.priority + 1
                    : device.priority - 1

                onSetNewPriority(device.id, newPriortiy)

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

        }  // :HStack
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
        DeviceRow(
            device: .init(
                id: "1",
                deviceType: .battery,
                name: "Battery",
                priority: 1,
                currentPowerInWatts: -540)
        ) { deviceId, newPriority in
        }
    }.background(Color.cyan.opacity(0.1))
        .frame(maxHeight: 60)
}

#Preview("Other") {
    VStack {
        DeviceRow(
            device: .init(
                id: "2",
                deviceType: .other,
                name: "Some device",
                priority: 2,
                currentPowerInWatts: 0)
        ) { deviceId, newPriority in
        }
    }.background(Color.cyan.opacity(0.1))
        .frame(maxHeight: 60)
}
