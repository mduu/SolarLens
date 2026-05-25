#if canImport(ActivityKit)
import SwiftUI

/// Per-automation body for Auto-reset Charging Mode runs. Mirrors the
/// in-app `AutoResetChargingModeRunningCard` layout 1:1 — three
/// stacked metrics (active mode, countdown, after-reset mode).
///
/// SwiftUI's native `Text(timerInterval:)` is the trick that makes this
/// LA useful even when the runner can't tick: iOS renders the countdown
/// itself, decrementing once per second, without our app or extension
/// being woken up.
struct AutoResetChargingModeCardBody: View {
    let payload: AutoResetChargingModePayload
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 8 : 10) {
            metric(
                label: "Active mode",
                value: payload.activeModeTitle
            )
            resetCountdown
            metric(
                label: "After reset",
                value: payload.afterResetModeTitle
            )
        }
    }

    private var resetCountdown: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Resets in")
                .font(.caption2)
                .foregroundStyle(.secondary)
            if payload.resetAt > Date() {
                Text(
                    timerInterval: Date()...payload.resetAt,
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
}
#endif
