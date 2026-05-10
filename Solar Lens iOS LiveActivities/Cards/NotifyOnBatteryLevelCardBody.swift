#if canImport(ActivityKit)
import SwiftUI

/// Per-automation body for "Notify on battery level" runs. Used by the
/// Lock Screen card and the Dynamic Island expanded view.
///
/// The body tells the user:
///   - the current observed battery level
///   - the threshold + comparison they're waiting for
///   - elapsed time since the run started
struct NotifyOnBatteryLevelCardBody: View {
    let payload: NotifyOnBatteryLevelPayload
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 4 : 8) {
            HStack(alignment: .firstTextBaseline, spacing: compact ? 12 : 18) {
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
            HStack(spacing: 10) {
                Label {
                    HStack(spacing: 3) {
                        Text("Running for")
                        Text(payload.startedAt, style: .timer)
                            .monospacedDigit()
                    }
                } icon: {
                    Image(systemName: "clock")
                }
                .labelStyle(.titleAndIcon)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }

    /// "Target reached in" metric rendered next to the Battery / Target
    /// metrics with the same top-label / bold-value layout. Uses
    /// `Text(timerInterval:)` so the countdown ticks down once per
    /// second without the runner needing to push updates.
    private func etaMetric(eta: Date) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("Target reached in")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(timerInterval: Date()...eta, countsDown: true)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
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
