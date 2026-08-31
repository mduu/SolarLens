#if canImport(ActivityKit)
import SwiftUI

/// Per-automation body for Auto-reset Charging Mode runs.
///
/// The two modes sit side by side rather than stacked: three stacked blocks
/// made the card taller than the ~160 pt the Lock Screen grants an activity,
/// so it was clipped top and bottom on device.
///
/// SwiftUI's native `Text(timerInterval:)` is the trick that makes this
/// LA useful even when the runner can't tick: iOS renders the countdown
/// itself, decrementing once per second, without our app or extension
/// being woken up.
struct AutoResetChargingModeCardBody: View {
    let payload: AutoResetChargingModePayload
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 6 : 8) {
            HStack(alignment: .top, spacing: 16) {
                metric(
                    label: "Active mode",
                    value: payload.activeModeTitle
                )
                metric(
                    label: "After reset",
                    value: payload.afterResetModeTitle
                )
            }
            resetCountdown
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
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
#endif
