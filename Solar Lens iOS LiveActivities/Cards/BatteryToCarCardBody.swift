#if canImport(ActivityKit)
import SwiftUI

/// Per-automation body for Battery → Car runs. Mirrors the in-app
/// `BatteryToCarRunningCard` metric layout 1:1 (minus title row and big
/// glyph, which the surrounding LA chrome already supplies):
///
///   Row 1:  Battery   Floor   Current
///   Row 2:  Trend     ∑ Total
///   Footer: Floor reached in 1h 23m  (only when forecast available)
///
/// Used by both the Lock Screen card and the Dynamic Island expanded
/// view. Reads only from the `BatteryToCarPayload` — never from the
/// runtime state — and inherits styling from `AutomationBrand`.
struct BatteryToCarCardBody: View {
    let payload: BatteryToCarPayload
    let primaryMetric: AutomationLiveActivityAttributes.ContentState.Metric
    let startedAt: Date
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 8 : 12) {
            HStack(alignment: .top, spacing: compact ? 14 : 18) {
                metric(
                    label: "Battery",
                    value: "\(payload.batterySoc)%"
                )
                metric(
                    label: "Floor",
                    value: "\(payload.floorSoc)%"
                )
                metric(
                    label: "Current",
                    value: "\(payload.currentAmps) A"
                )
            }

            HStack(alignment: .top, spacing: compact ? 14 : 18) {
                if let rate = BatteryRateFormatter.format(
                    rateW: payload.lastBatteryChargeRateW
                ) {
                    metric(label: "Trend", value: rate)
                }
                metricRaw(
                    label: primaryMetric.label,
                    value: primaryMetric.value
                )
            }

            if let eta = payload.forecastedFloorAt, eta > Date() {
                forecastMetric(label: "Floor reached in", eta: eta)
            }
        }
    }

    /// "Floor reached in 1h 23m" using the system
    /// `Text(timerInterval:)` so the LA renders the countdown without
    /// the runner needing to push updates.
    private func forecastMetric(
        label: LocalizedStringKey, eta: Date
    ) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "clock")
                .foregroundStyle(.secondary)
            Text(label)
                .foregroundStyle(.secondary)
            Text(timerInterval: Date()...eta, countsDown: true)
                .monospacedDigit()
                .foregroundStyle(.primary)
        }
        .font(.caption.weight(.semibold))
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

    /// For metric labels that are already localised at the source (the
    /// app process produces them, the widget extension just renders).
    private func metricRaw(
        label: String, value: String
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
