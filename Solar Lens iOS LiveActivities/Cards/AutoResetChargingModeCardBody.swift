#if canImport(ActivityKit)
import SwiftUI

/// Per-automation body for Auto-reset Charging Mode runs. Used by the
/// Lock Screen card and the Dynamic Island expanded view.
///
/// SwiftUI's native `Text(timerInterval:)` is the trick that makes this
/// LA useful even when the runner can't tick: iOS renders the countdown
/// itself, decrementing once per second, without our app or extension
/// being woken up.
struct AutoResetChargingModeCardBody: View {
    let payload: AutoResetChargingModePayload
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 4 : 8) {
            HStack(alignment: .firstTextBaseline, spacing: compact ? 12 : 18) {
                metric(
                    label: "Active mode",
                    value: payload.activeModeTitle
                )
                resetCountdown
            }
            HStack(spacing: 10) {
                Label(
                    "Resets to \(payload.afterResetModeTitle)",
                    systemImage: "arrow.uturn.backward"
                )
                .labelStyle(.titleAndIcon)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }

    private var resetCountdown: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("Resets in")
                .font(.caption2)
                .foregroundStyle(.secondary)
            if payload.resetAt > Date() {
                Text(
                    timerInterval: Date()...payload.resetAt,
                    countsDown: true
                )
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
            } else {
                Text("now")
                    .font(.subheadline.weight(.semibold))
            }
        }
    }

    private func metric(
        label: LocalizedStringKey, value: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
    }
}
#endif
