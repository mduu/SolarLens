import SwiftUI

/// Live state card while the Auto-reset Charging Mode automation is
/// running. Uses SwiftUI's native `Text(timerInterval:)` for the countdown
/// — the timer continues to update even when the runner isn't ticking.
struct AutoResetChargingModeRunningCard: View {
    let state: AutomationAutoResetChargingModeState
    let params: AutomationAutoResetChargingModeParameters
    let onCancel: () -> Void

    private let cornerRadius: CGFloat = 20

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: AutomationBrand.accentSymbol)
                    .foregroundStyle(.primary)
                Text("Auto-reset Charging Mode running")
                    .font(.headline)
                Spacer()
                HStack(spacing: 5) {
                    Image(
                        systemName: Automation.AutoResetChargingMode
                            .liveActivityIconSystemName
                    )
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

            VStack(alignment: .leading, spacing: 10) {
                metric(
                    label: "Active mode",
                    value: localizedTitle(of: params.activeChargingMode)
                )
                resetCountdown
                metric(
                    label: "After reset",
                    value: localizedTitle(of: params.afterResetChargingMode)
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

    /// Live countdown to the reset moment. SwiftUI re-renders this `Text`
    /// once per second on its own — no app or runner ticks needed.
    private var resetCountdown: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Resets in")
                .font(.caption2)
                .foregroundStyle(.secondary)
            if params.resetAt > Date() {
                Text(
                    timerInterval: Date()...params.resetAt,
                    countsDown: true
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .monospacedDigit()
            } else {
                Text("now")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
        }
    }

    private func metric(
        label: LocalizedStringKey, value: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
    }

    private func localizedTitle(of mode: ChargingMode) -> String {
        String(localized: mode.localizedTitle)
    }
}
