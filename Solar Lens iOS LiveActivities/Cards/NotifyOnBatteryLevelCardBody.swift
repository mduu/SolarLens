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
            }
            HStack(spacing: 10) {
                Label("Running for \(elapsedShort)", systemImage: "clock")
                    .labelStyle(.titleAndIcon)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }

    private var comparator: String {
        switch payload.comparison {
        case .equalOrAbove: return "≥"
        case .equalOrBelow: return "≤"
        }
    }

    private var elapsedShort: String {
        let seconds = max(0, Int(Date().timeIntervalSince(payload.startedAt)))
        let m = seconds / 60
        if m < 1 { return "<1m" }
        if m < 60 { return "\(m)m" }
        let h = m / 60
        let rem = m % 60
        return rem == 0 ? "\(h)h" : "\(h)h \(rem)m"
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
