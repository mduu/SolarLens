#if canImport(ActivityKit)
import SwiftUI

/// Per-automation body for "Notify on battery level" runs. Mirrors the
/// in-app `NotifyOnBatteryLevelRunningCard` metric layout 1:1 (minus
/// the title row and big glyph supplied by the surrounding LA chrome):
///
///   Row 1:  Battery   Target   Target reached in (if forecast known)
///   Row 2:  Running for X   Trend (if available)
struct NotifyOnBatteryLevelCardBody: View {
    let payload: NotifyOnBatteryLevelPayload
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 8 : 12) {
            HStack(alignment: .top, spacing: compact ? 14 : 18) {
                metric(
                    label: "Battery",
                    value: payload.lastBatteryLevel
                        .map { "\($0)%" } ?? "—"
                )
                metric(
                    label: "Target",
                    value: "\(comparator) \(payload.targetBatteryLevel)%"
                )
                if let eta = payload.forecastedTargetAt, eta > Date() {
                    etaMetric(eta: eta)
                }
            }

            HStack(alignment: .top, spacing: compact ? 14 : 18) {
                runningForMetric
                if let rate = BatteryRateFormatter.format(
                    rateW: payload.lastBatteryChargeRateW
                ) {
                    metric(label: "Trend", value: rate)
                }
            }
        }
    }

    /// "Running for X" rendered as a top-label / bold-value metric like
    /// the rest, with a live `Text(_:style: .timer)` so the elapsed
    /// counter ticks up without our app being involved.
    private var runningForMetric: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Running for")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(payload.startedAt, style: .timer)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.primary)
        }
    }

    /// "Target reached in" rendered next to Battery / Target with the
    /// same top-label / bold-value layout. Uses `Text(timerInterval:)`
    /// so the countdown ticks once per second without runner updates.
    private func etaMetric(eta: Date) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Target reached in")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(timerInterval: Date()...eta, countsDown: true)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private var comparator: String {
        switch payload.comparison {
        case .equalOrAbove: return "≥"
        case .equalOrBelow: return "≤"
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
