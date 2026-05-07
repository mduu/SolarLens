internal import Foundation

enum SoftFloor {
    static let minBufferPct: Double = 1.0
    static let maxBufferPct: Double = 8.0
    static let safetyFactor: Double = 1.5

    /// Compute the predictive safety buffer (in % battery SoC) that we keep
    /// between the *current* battery level and the user's soft floor.
    ///
    /// The buffer scales with how stale our last tick was — in foreground
    /// (≈1 min) it collapses to ~1%; in background with a 20-min gap it
    /// could grow large but is hard-capped at `maxBufferPct` so a low
    /// user-floor never becomes unreachable.
    ///
    /// - Parameters:
    ///   - dischargeW: current whole-house draw on the battery (W).
    ///   - batteryCapacityKwh: total capacity across all batteries (kWh).
    ///   - smoothedTickIntervalMinutes: EWMA of recent tick gaps (min).
    static func computeSafetyBuffer(
        dischargeW: Int,
        batteryCapacityKwh: Double,
        smoothedTickIntervalMinutes: Double
    ) -> Double {
        guard dischargeW > 0, batteryCapacityKwh > 0 else {
            return minBufferPct
        }

        let onePercentWh = (batteryCapacityKwh * 1000.0) / 100.0
        let percentPerMin = (Double(dischargeW) / onePercentWh) / 60.0
        let raw = percentPerMin
            * smoothedTickIntervalMinutes
            * safetyFactor

        return min(maxBufferPct, max(minBufferPct, ceil(raw)))
    }

    /// EWMA update for the tick-interval estimate.
    static func updatedTickInterval(
        previousMinutes: Double,
        observedMinutes: Double,
        alpha: Double = 0.4
    ) -> Double {
        let clampedObserved = max(0.5, observedMinutes)
        return alpha * clampedObserved
            + (1.0 - alpha) * previousMinutes
    }
}
