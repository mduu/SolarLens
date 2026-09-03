import SwiftUI

/// How the battery stood on a day that has already ended.
struct BatteryDaySummary {
    let endOfDay: Int
    let low: Int
    let high: Int
}

struct BatteryStatusCard: View {
    var level: Int = 0
    var charging: Int = 0
    var forecastText: String? = nil

    /// Set when the card sits above a chart of an earlier day. The live level,
    /// charge rate and forecast all describe *now*; left in place next to a
    /// past day's chart they read as that day's figures.
    var daySummary: BatteryDaySummary? = nil

    private var shownLevel: Int { daySummary?.endOfDay ?? level }
    private var shownCharging: Int { daySummary == nil ? charging : 0 }

    private var batteryColor: Color {
        if shownLevel > 10 { return .green }
        if shownLevel > 6 { return .orange }
        return .red
    }

    private var iconName: String {
        if shownCharging > 0 { return "battery.100percent.bolt" }
        if shownLevel >= 95 { return "battery.100percent" }
        if shownLevel >= 70 { return "battery.75percent" }
        if shownLevel >= 50 { return "battery.50percent" }
        if shownLevel >= 10 { return "battery.25percent" }
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
                            isActive: shownCharging > 0
                        )
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Text("\(shownLevel)%")
                            .font(.headline)
                            .fontWeight(.bold)

                        if daySummary != nil {
                            Text("at end of day")
                                .font(.caption)
                                .foregroundStyle(.primary.opacity(0.7))
                        }

                        if shownCharging != 0 {
                            HStack(spacing: 4) {
                                Image(systemName: shownCharging > 0 ? "arrow.up" : "arrow.down")
                                    .font(.caption)
                                    .foregroundStyle(shownCharging > 0 ? .green : .orange)
                                Text(abs(shownCharging).formatWattsAsWattsKiloWatts(widthUnit: true))
                                    .font(.subheadline)
                                    .foregroundStyle(.primary.opacity(0.7))
                            }
                        }
                    }

                    BatteryLevelBar(level: shownLevel, color: batteryColor)

                    if let daySummary {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.and.down")
                                .font(.caption2)
                                .foregroundStyle(.primary.opacity(0.7))
                            Text("Between \(daySummary.low)% and \(daySummary.high)% that day")
                                .font(.caption2)
                                .foregroundStyle(.primary.opacity(0.7))
                        }
                    } else if let forecastText {
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

