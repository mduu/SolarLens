import SwiftUI

/// Tile shown when a given notification kind IS enabled.
///
/// Single tap → edit (re-open the setup sheet). Disable button in the
/// top-trailing corner removes the monitor.
///
/// Laid out as a compact grid tile (two columns on the Notifications
/// screen): threshold + live value + arm state, in as little height as
/// possible. The full fire history lives in `NotificationHistoryView`,
/// so "last fired" is not repeated here.
struct NotificationRunningRow: View {
    let monitor: NotificationMonitor
    let onDisable: () -> Void
    let onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Image(systemName: monitor.kind.iconSystemName)
                        .font(.system(size: 26, weight: .regular))
                        .foregroundStyle(.green)
                        .symbolRenderingMode(.hierarchical)
                        .accessibilityHidden(true)
                    Spacer(minLength: 0)
                    Button(role: .destructive) {
                        onDisable()
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.red.opacity(0.85))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Disable notification")
                }

                Text(String(localized: monitor.kind.localizedTitleKey))
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2, reservesSpace: true)

                HStack(spacing: 6) {
                    Text(thresholdDescription)
                        .font(.subheadline.weight(.semibold))
                    repeatIcon
                }

                VStack(alignment: .leading, spacing: 2) {
                    if let value = monitor.lastValue {
                        Text(
                            String(
                                localized:
                                    "Now: \(formatValue(value, for: monitor.kind))"
                            )
                        )
                    }
                    stateText
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .padding(12)
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

    @ViewBuilder
    private var stateText: some View {
        switch monitor.armState {
        case .armed:
            Text("Watching")
        case .firedWaitingForReset:
            Text("Waiting to re-arm")
        }
    }

    /// Icon-only repeat mode (tile width is scarce); the meaning is
    /// spelled out for VoiceOver.
    private var repeatIcon: some View {
        Image(
            systemName: monitor.repeatMode == .once
                ? "1.circle" : "arrow.triangle.2.circlepath"
        )
        .font(.caption)
        .foregroundStyle(.secondary)
        .accessibilityLabel(
            monitor.repeatMode == .once
                ? Text("Notify once")
                : Text("Notify on every re-occurrence")
        )
    }

    private func formatValue(
        _ value: Int, for kind: SolarLensNotification
    ) -> String {
        if kind.isPercent {
            return "\(value)%"
        }
        return String(format: "%.1f kW", Double(value) / 1000.0)
    }
}
