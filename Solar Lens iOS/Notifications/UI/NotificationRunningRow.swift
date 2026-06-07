import SwiftUI

/// Row shown when a given notification kind IS enabled.
///
/// Single tap → edit (re-open the setup sheet). Disable button on the
/// trailing edge removes the monitor.
struct NotificationRunningRow: View {
    let monitor: NotificationMonitor
    let onDisable: () -> Void
    let onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: monitor.kind.iconSystemName)
                    .font(.system(size: 36, weight: .regular))
                    .foregroundStyle(.green)
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 44)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(String(localized: monitor.kind.localizedTitleKey))
                            .font(.headline)
                        Spacer(minLength: 0)
                        Button(role: .destructive) {
                            onDisable()
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.red.opacity(0.85))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Disable notification")
                    }

                    Text(thresholdDescription)
                        .font(.subheadline.weight(.semibold))

                    HStack(spacing: 16) {
                        if let value = monitor.lastValue {
                            metric(
                                label: "Now",
                                value: formatValue(value, for: monitor.kind)
                            )
                        }
                        if let lastFired = monitor.lastFiredAt {
                            metric(
                                label: "Last fired",
                                value: shortAgo(since: lastFired)
                            )
                        }
                        switch monitor.armState {
                        case .armed:
                            metric(
                                label: "State",
                                value: String(localized: "Watching")
                            )
                        case .firedWaitingForReset:
                            metric(
                                label: "State",
                                value: String(localized: "Waiting to re-arm")
                            )
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    repeatBadge
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16).fill(.regularMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.green.opacity(0.6), lineWidth: 2)
            )
            .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
    }

    private var thresholdDescription: String {
        let comparator: String
        switch monitor.comparison {
        case .equalOrAbove: comparator = "≥"
        case .equalOrBelow: comparator = "≤"
        }
        return "\(comparator) \(formatValue(monitor.threshold, for: monitor.kind))"
    }

    private var repeatBadge: some View {
        HStack(spacing: 4) {
            Image(
                systemName: monitor.repeatMode == .once
                    ? "1.circle" : "arrow.triangle.2.circlepath"
            )
            Text(
                monitor.repeatMode == .once
                    ? "Notify once" : "Notify on every re-occurrence"
            )
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
    }

    private func metric(label: LocalizedStringKey, value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
        }
    }

    private func formatValue(
        _ value: Int, for kind: SolarLensNotification
    ) -> String {
        if kind.isPercent {
            return "\(value)%"
        }
        return String(format: "%.1f kW", Double(value) / 1000.0)
    }

    private func shortAgo(since date: Date) -> String {
        let secs = max(0, Int(Date().timeIntervalSince(date)))
        if secs < 60 { return "\(secs)s" }
        let m = secs / 60
        if m < 60 { return "\(m)m" }
        let h = m / 60
        return "\(h)h"
    }
}
