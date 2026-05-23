import SwiftUI

/// Watch idle card for the Battery → Car automation. Tap to open setup
/// sheet (when not disabled).
struct BatteryToCarCard: View {
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
                    Image(systemName: "bolt.car.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.orange)
                        .font(.title3)
                    Text("Battery → Car")
                        .font(.headline)
                        .lineLimit(1)
                }
                Text(
                    "Charge the car from the house battery down to a floor."
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                if let msg = disabledMessage {
                    Text(msg)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThickMaterial)
            )
            .opacity(disabled ? 0.85 : 1)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}
