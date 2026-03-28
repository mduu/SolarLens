import SwiftUI

struct BatteryStatusCard: View {
    let level: Int
    let charging: Int
    let forecastText: String?

    private var batteryColor: Color {
        if level > 10 { return .green }
        if level > 6 { return .orange }
        return .red
    }

    private var iconName: String {
        if charging > 0 { return "battery.100percent.bolt" }
        if level >= 95 { return "battery.100percent" }
        if level >= 70 { return "battery.75percent" }
        if level >= 50 { return "battery.50percent" }
        if level >= 10 { return "battery.25percent" }
        return "battery.0percent"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "battery.100percent")
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.7))
                Text("Battery")
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.7))
            }

            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(batteryColor.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: iconName)
                        .font(.title3)
                        .foregroundStyle(batteryColor)
                        .symbolEffect(
                            .pulse.wholeSymbol,
                            options: .repeat(.continuous),
                            isActive: charging > 0
                        )
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Text("\(level)%")
                            .font(.headline)
                            .fontWeight(.bold)

                        if charging != 0 {
                            HStack(spacing: 4) {
                                Image(systemName: charging > 0 ? "arrow.up" : "arrow.down")
                                    .font(.caption)
                                    .foregroundStyle(charging > 0 ? .green : .orange)
                                Text(abs(charging).formatWattsAsWattsKiloWatts(widthUnit: true))
                                    .font(.subheadline)
                                    .foregroundStyle(.primary.opacity(0.7))
                            }
                        }
                    }

                    BatteryLevelBar(level: level, color: batteryColor)

                    if let forecastText {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                                .foregroundStyle(.primary.opacity(0.7))
                            Text(forecastText)
                                .font(.caption2)
                                .foregroundStyle(.primary.opacity(0.7))
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}

