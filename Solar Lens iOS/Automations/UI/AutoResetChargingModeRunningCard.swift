import SwiftUI

/// Live state card while the Auto-reset Charging Mode automation is
/// running. Native `Text(timerInterval:)` keeps the countdown ticking
/// without any runner involvement.
///
/// Layout: large per-automation glyph on the left, title + metrics
/// flowing to the right of it, and a round red Stop button anchored
/// top-right as the cancel affordance.
struct AutoResetChargingModeRunningCard: View {
    let state: AutomationAutoResetChargingModeState
    let params: AutomationAutoResetChargingModeParameters
    let onCancel: () -> Void

    private let cornerRadius: CGFloat = 20

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 16) {
                Image(
                    systemName: Automation.AutoResetChargingMode
                        .liveActivityIconSystemName
                )
                .font(.system(size: 56, weight: .regular))
                .foregroundStyle(.orange)
                .symbolRenderingMode(.hierarchical)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 12) {
                        Text("Auto-reset Charging Mode running")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        AutomationCircularCancelButton(action: onCancel)
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
