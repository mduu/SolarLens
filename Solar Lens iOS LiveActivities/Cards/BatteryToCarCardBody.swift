#if canImport(ActivityKit)
import SwiftUI

/// Per-automation body for Battery → Car runs. Used by the Lock Screen card
/// and the Dynamic Island expanded view. Reads only the `BatteryToCarPayload`
/// — never the runtime `AutomationBatteryToCarState` — and inherits all
/// brand styling from `AutomationBrand`.
struct BatteryToCarCardBody: View {
    let payload: BatteryToCarPayload
    let primaryMetric: AutomationLiveActivityAttributes.ContentState.Metric
    let startedAt: Date
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 4 : 8) {
            HStack(alignment: .firstTextBaseline, spacing: compact ? 12 : 18) {
                metric(
                    label: "Battery",
                    value: "\(payload.batterySoc)%"
                )
                metric(
                    label: "Current",
                    value: "\(payload.currentAmps) A"
                )
                metricRaw(
                    label: primaryMetric.label,
                    value: primaryMetric.value
                )
            }
            HStack(spacing: 10) {
                Label("Floor \(payload.floorSoc)%", systemImage: "arrow.down.to.line")
                    .labelStyle(.titleAndIcon)
                Text("•")
                Text("\(elapsedShort) ago")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }

    private var elapsedShort: String {
        let seconds = max(0, Int(Date().timeIntervalSince(startedAt)))
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

    /// For metric labels that are already localised at the source (the
    /// app process produces them, the widget extension just renders).
    private func metricRaw(
        label: String, value: String
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
