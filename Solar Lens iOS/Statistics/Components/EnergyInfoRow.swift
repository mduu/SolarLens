import SwiftUI

struct EnergyInfoRow: View {
    var carCharged: Double
    var batteryCharged: Double
    var batteryDischarged: Double
    var isCurrentlyCharging: Bool
    var useMWh: Bool = false
    var hasCarChargingStation: Bool = true
    var hasBattery: Bool = true

    @Environment(\.colorScheme) private var colorScheme

    private func format(_ value: Double) -> String {
        if useMWh {
            return String(format: "%.1f MWh", value / 1_000_000)
        }
        return String(format: "%.1f kWh", value / 1000)
    }

    var body: some View {
        if hasCarChargingStation || hasBattery {
            HStack(spacing: 8) {
                if hasCarChargingStation {
                    HStack(spacing: 6) {
                        Image(systemName: "car.side.fill")
                            .font(.callout)
                            .foregroundStyle(.green.opacity(0.7))
                        Text(format(carCharged))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .containerRelativeFrame(.horizontal) { width, _ in
                        width / 3 - 12
                    }
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                }

                if hasBattery {
                    HStack(spacing: 8) {
                        Image(systemName: "battery.100")
                            .font(.callout)
                            .foregroundStyle(.purple.opacity(0.7))

                        HStack(spacing: 3) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                            Text(format(batteryCharged))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }

                        HStack(spacing: 3) {
                            Image(systemName: "arrow.backward.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                            Text(format(batteryDischarged))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.purple.opacity(colorScheme == .dark ? 0.25 : 0.12), in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal)
            .padding(.top, 4)
        }
    }
}
