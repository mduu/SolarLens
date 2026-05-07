import SwiftUI

/// Live state card while the Battery-to-Car automation is running.
/// Visually distinct from the idle card: bright material fill with a
/// rotating animated gradient border (vs. the idle card's flat gradient).
struct BatteryToCarRunningCard: View {
    let state: AutomationBatteryToCarState
    let params: AutomationBatteryToCarParameters
    let onCancel: () -> Void

    private let cornerRadius: CGFloat = 20

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("Battery → Car running")
                    .font(.headline)
                Spacer()
                HStack(spacing: 5) {
                    Image(systemName: "rocket.fill")
                        .symbolEffect(.pulse, options: .repeating)
                        .symbolRenderingMode(.monochrome)
                    Text("Running")
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(Color(red: 0.13, green: 0.66, blue: 0.32))
                )
                .foregroundStyle(.white)
            }

            HStack(spacing: 24) {
                metric(
                    label: "Battery",
                    value: "\(state.lastBatteryPercentage ?? state.startSoc)%"
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

            Button(role: .destructive, action: onCancel) {
                Label("Cancel automation", systemImage: "stop.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red.opacity(0.85))
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
