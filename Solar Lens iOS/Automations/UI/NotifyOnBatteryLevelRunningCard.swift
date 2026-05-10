import SwiftUI

/// Live state card while the "Notify on battery level" automation is
/// running.
struct NotifyOnBatteryLevelRunningCard: View {
    let state: AutomationNotifyOnBatteryLevelState
    let params: AutomationNotifyOnBatteryLevelParameters
    let onCancel: () -> Void

    private let cornerRadius: CGFloat = 20

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 16) {
                Image(
                    systemName: Automation.NotifyOnBatteryLevel
                        .liveActivityIconSystemName
                )
                .font(.system(size: 56, weight: .regular))
                .foregroundStyle(.orange)
                .symbolRenderingMode(.hierarchical)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 12) {
                        Text("Notify on battery level")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        AutomationCircularCancelButton(action: onCancel)
                    }

                    HStack(alignment: .top, spacing: 24) {
                        metric(
                            label: "Battery",
                            value: state.lastBatteryLevel
                                .map { "\($0)%" } ?? "—"
                        )
                        metric(
                            label: "Target",
                            value: "\(comparator) \(params.targetBatteryLevel)%"
                        )
                        if let eta = state.forecastedTargetAt,
                           eta > Date()
                        {
                            etaMetric(eta: eta)
                        }
                    }

                    HStack(alignment: .top, spacing: 24) {
                        if let started = state.startedAt {
                            metric(
                                label: "Running for",
                                value: elapsed(since: started)
                            )
                        }
                        if let rate = BatteryRateFormatter.format(
                            rateW: state.lastBatteryChargeRate
                        ) {
                            metric(label: "Trend", value: rate)
                        }
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

    private var comparator: String {
        switch params.comparison {
        case .equalOrAbove: return "≥"
        case .equalOrBelow: return "≤"
        }
    }

    private func elapsed(since start: Date) -> String {
        let secs = max(0, Int(Date().timeIntervalSince(start)))
        let m = secs / 60
        if m < 1 { return "<1m" }
        if m < 60 { return "\(m)m" }
        let h = m / 60
        let rem = m % 60
        return rem == 0 ? "\(h)h" : "\(h)h \(rem)m"
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

    /// "Target reached in" metric rendered next to the Battery / Target
    /// metrics with the same top-label / bold-value layout. Uses
    /// `Text(timerInterval:)` so the countdown ticks down once per
    /// second without the runner re-rendering the card.
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
}
