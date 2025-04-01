import SwiftUI

struct DeviceConnectionIndicator: View {
    var device: Device

    var body: some View {
        if device.hasError {
            WidthExplanation(
                explanation:
                    "Device has an error! Check Solar Manaager so find out more."
            ) {
                Image(
                    systemName:
                        "antenna.radiowaves.left.and.right.slash.circle.fill"
                )
                .foregroundColor(.red)
                .symbolEffect(
                    .bounce.up.byLayer,
                    options: .repeat(.periodic(delay: 2.0))
                )
            }
        } else if device.signal == .notConnected {
            WidthExplanation(explanation: "Device is not connected.") {
                Image(
                    systemName: "antenna.radiowaves.left.and.right.circle.fill"
                )
                .foregroundColor(.orange)
                .symbolEffect(
                    .wiggle.byLayer,
                    options: .repeat(.periodic(delay: 2.0))
                )
            }
        } else if device.signal == .connected {
            WidthExplanation(
                explanation: "Device is connected and ready to use."
            ) {
                Image(systemName: "antenna.radiowaves.left.and.right.circle")
                    .foregroundColor(.green)
            }
        }

    }
}

#Preview {
    VStack(spacing: 10) {
        DeviceConnectionIndicator(
            device: .init(
                id: "1",
                deviceType: .other,
                name: "The device",
                priority: 1,
                currentPowerInWatts: 1234,
                color: nil,
                signal: .connected,
                hasError: false
            )
        )

        DeviceConnectionIndicator(
            device: .init(
                id: "1",
                deviceType: .other,
                name: "The device",
                priority: 1,
                currentPowerInWatts: 1234,
                color: nil,
                signal: .notConnected,
                hasError: false
            )
        )

        DeviceConnectionIndicator(
            device: .init(
                id: "1",
                deviceType: .other,
                name: "The device",
                priority: 1,
                currentPowerInWatts: 1234,
                color: nil,
                signal: .notConnected,
                hasError: true
            )
        )

        DeviceConnectionIndicator(
            device: .init(
                id: "1",
                deviceType: .other,
                name: "The device",
                priority: 1,
                currentPowerInWatts: 1234,
                color: nil,
                signal: .connected,
                hasError: true
            )
        )

        Spacer()
    }
}
