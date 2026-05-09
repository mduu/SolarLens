import SwiftUI

/// Watch idle card for the Notify on Battery Level automation.
struct NotifyOnBatteryLevelCard: View {
    let isOtherActive: Bool
    let isHouseBatteryMissing: Bool
    let onTap: () -> Void

    private var disabled: Bool { isOtherActive || isHouseBatteryMissing }

    private var disabledMessage: LocalizedStringResource? {
        if isHouseBatteryMissing { return "Requires a house battery" }
        if isOtherActive { return "Another automation is active" }
        return nil
    }

    var body: some View {
        Button(action: { if !disabled { onTap() } }) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "bell.badge.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.orange)
                        .font(.title3)
                    Text("Battery Alert")
                        .font(.headline)
                        .lineLimit(1)
                }
                Text(
                    "Notify when battery hits a target level."
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
