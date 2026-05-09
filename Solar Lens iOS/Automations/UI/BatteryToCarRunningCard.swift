import SwiftUI

/// Live state card while the Battery-to-Car automation is running.
/// Visually distinct from the idle card: bright material fill with a
/// rotating animated gradient border (vs. the idle card's flat gradient).
///
/// Layout: large per-automation glyph on the left, title + metrics
/// flowing to the right of it, and a round red Stop button anchored
/// top-right as the cancel affordance.
struct BatteryToCarRunningCard: View {
    let state: AutomationBatteryToCarState
    let params: AutomationBatteryToCarParameters
    let onCancel: () -> Void

    private let cornerRadius: CGFloat = 20

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: "bolt.car.circle.fill")
                    .font(.system(size: 56, weight: .regular))
                    .foregroundStyle(.orange)
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 12) {
                        Text("Battery → Car running")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        AutomationCircularCancelButton(action: onCancel)
                    }

                    HStack(alignment: .top, spacing: 18) {
                        metric(
                            label: "Battery",
                            value:
                                "\(state.lastBatteryPercentage ?? state.startSoc)%"
                        )
                        metric(
                            label: "Floor",
                            value: "\(params.minBatteryLevel)%"
                        )
                        metric(
                            label: "Current",
                            value: "\(state.currentAmps) A"
                        )
                        metric(
                            label: "Transferred",
                            value: String(
                                format: "%.2f kWh", state.kWhTransferred
                            )
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.regularMaterial)
        )
        .overlay(
            AICardBorder(
                cornerRadius: cornerRadius,
                lineWidth: 5
            )
        )
        .background(
            AICardGlow(cornerRadius: cornerRadius)
                .padding(-6)
        )
    }

    private func metric(label: LocalizedStringKey, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
    }
}
