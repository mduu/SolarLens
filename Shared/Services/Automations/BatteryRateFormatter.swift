internal import Foundation

/// Formats a house-battery charge rate (W) for the automation cards.
/// - Positive (>50 W): "+1.5 kW ↑"
/// - Negative (<-50 W): "-0.5 kW ↓"
/// - Within ±50 W: "Idle" (the same threshold the forecast helper uses
///   to consider the battery idle, so this matches why no forecast).
/// - `nil`: returns `nil` so the caller can hide the row entirely.
enum BatteryRateFormatter {
    /// Threshold matches `OverviewData.forecastSeconds` and the in-app
    /// battery sheet — anything within ±50 W is "idle" / not flowing.
    static let idleThresholdW = 50

    static func format(rateW: Int?) -> String? {
        guard let rateW else { return nil }
        if abs(rateW) <= idleThresholdW {
            return String(localized: "Idle")
        }
        let kW = Double(rateW) / 1000.0
        let sign = rateW > 0 ? "+" : ""
        let arrow = rateW > 0 ? "↑" : "↓"
        // Formatted here rather than through `Double.localized(decimals:)`:
        // this file is also compiled into the Live Activity extension, which
        // does not carry the shared extensions.
        let figure = kW.formatted(.number.precision(.fractionLength(1)))
        return "\(sign)\(figure) kW \(arrow)"
    }
}
