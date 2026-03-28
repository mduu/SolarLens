import SwiftUI

struct WatchBatteryStatusView: View {
    let level: Int
    let charging: Int

    private var color: Color {
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
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.title3)
                    .foregroundStyle(color)
                    .symbolEffect(
                        .pulse.wholeSymbol,
                        options: .repeat(.continuous),
                        isActive: charging > 0
                    )

                Text("\(level)%")
                    .font(.title3)
                    .fontWeight(.bold)

                if charging != 0 {
                    HStack(spacing: 2) {
                        Image(systemName: charging > 0 ? "arrow.up" : "arrow.down")
                            .font(.caption2)
                            .foregroundStyle(charging > 0 ? .green : .orange)
                        Text(abs(charging).formatWattsAsWattsKiloWatts(widthUnit: true))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            BatteryLevelBar(level: level, color: color, height: 8)
        }
    }
}
