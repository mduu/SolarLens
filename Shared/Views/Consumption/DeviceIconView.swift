import SwiftUI

struct DeviceIconView: View {
    var device: Device

    var body: some View {
        if device.deviceType == .battery {
            BatteryIcon(for: device)
        } else if device.deviceType == .carCharging {
            ChargingStationIcon(for: device)
        } else if device.deviceType == .energyMeasurement {
            EnergyMeasurement(for: device)
        } else {
            GenericDeviceIcon(for: device)
        }
    }

    func BatteryIcon(for device: Device) -> some View {
        VStack {
            if device.currentPowerInWatts > 10 {
                Image(systemName: "battery.100percent.bolt")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.green, .primary)
                    .symbolEffect(.pulse, options: .repeat(.continuous))
            } else if device.currentPowerInWatts < -10 {
                Image(systemName: "battery.100percent")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.orange, .primary)
                    .symbolEffect(.pulse)
            } else {
                Image(systemName: "battery.100percent")
            }
        }
    }

    func ChargingStationIcon(for device: Device) -> some View {
        VStack {
            if device.currentPowerInWatts > 10 {
                Image(systemName: "fuelpump.arrowtriangle.right")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.green, .primary)
                    .symbolEffect(
                        .breathe.pulse.wholeSymbol,
                        options: .repeat(.continuous))
            } else {
                Image(systemName: "fuelpump")
            }
        }
    }

    func EnergyMeasurement(for device: Device) -> some View {
        VStack {
            if device.currentPowerInWatts > 10 {
                Image(systemName: "gauge.with.dots.needle.50percent")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.orange, .primary)
                    .symbolEffect(.pulse)
            } else {
                Image(systemName: "gauge.with.dots.needle.50percent")
            }
        }
    }

    func GenericDeviceIcon(for device: Device) -> some View {
        VStack {
            if device.currentPowerInWatts > 10 {
                Image(systemName: "powerplug.portrait")
                    .symbolEffect(
                        .breathe.pulse.wholeSymbol,
                        options: .repeat(.continuous))
            } else {
                Image(systemName: "powerplug.portrait")
            }
        }
    }
}

#Preview("Battery out") {
    DeviceIconView(
        device: .init(
            id: "1", deviceType: .battery, priority: 1,
            currentPowerInWatts: -4563)
    )
}

#Preview("Battery in") {
    DeviceIconView(
        device: .init(
            id: "1", deviceType: .battery, priority: 1,
            currentPowerInWatts: 1563)
    )
}

#Preview("Battery neutral") {
    DeviceIconView(
        device: .init(
            id: "1", deviceType: .battery, priority: 1,
            currentPowerInWatts: 8)
    )
}

#Preview("Device consuming") {
    DeviceIconView(
        device: .init(
            id: "1", deviceType: .other, priority: 1, currentPowerInWatts: 1563)
    )
}

#Preview("Device not consuming") {
    DeviceIconView(
        device: .init(
            id: "1", deviceType: .other, priority: 1, currentPowerInWatts: 10)
    )
}

#Preview("Car charging") {
    DeviceIconView(
        device: .init(
            id: "1", deviceType: .carCharging, priority: 1,
            currentPowerInWatts: 10456)
    )
}

#Preview("Car charging not charging") {
    DeviceIconView(
        device: .init(
            id: "1", deviceType: .carCharging, priority: 1,
            currentPowerInWatts: 0)
    )
}
