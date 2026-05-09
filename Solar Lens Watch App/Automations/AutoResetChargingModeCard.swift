import SwiftUI

/// Watch idle card for the Auto-reset Charging Mode automation.
struct AutoResetChargingModeCard: View {
    let isOtherActive: Bool
    let isChargingStationMissing: Bool
    let onTap: () -> Void

    private var disabled: Bool {
        isOtherActive || isChargingStationMissing
    }

    private var disabledMessage: LocalizedStringResource? {
        if isChargingStationMissing { return "Requires a charging station" }
        if isOtherActive { return "Another automation is active" }
        return nil
    }

    var body: some View {
        Button(action: { if !disabled { onTap() } }) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "timer.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.orange)
                        .font(.title3)
                    Text("Auto-reset Mode")
                        .font(.headline)
                        .lineLimit(1)
                }
                Text(
                    "Switch the wallbox now and reset to another mode later."
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                if let msg = disabledMessage {
                    Text(msg)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThickMaterial)
            )
            .opacity(disabled ? 0.5 : 1)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}
