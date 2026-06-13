internal import Foundation

enum SoftFloor {
    static let minBufferPct: Double = 1.0
    static let maxBufferPct: Double = 8.0
    static let safetyFactor: Double = 1.5

    /// Width of the "glide path" toward the soft floor, in % battery SoC.
    /// Within this band above the floor the car amperage is ramped down
    /// toward the protocol minimum so the last stretch drains slowly.
    ///
    /// Deliberately wider than `maxBufferPct`: the predictive stop fires
    /// when `current − buffer ≤ floor`, and the buffer scales with the
    /// discharge rate. By forcing the discharge rate *down* before we get
    /// that close, the buffer collapses (a slow drain can only fall ~1–2%
    /// between background ticks), so the stop lands near the floor instead
    /// of several % early — and any overshoot during a blind BG gap stays
    /// tiny because the rate is already low. The band must exceed the
    /// buffer or the stop would trigger before the glide has slowed the
    /// drain at all.
    static let glideBandPct: Double = 8.0

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

    /// Glide-path clamp for the final approach to the soft floor.
    ///
    /// Returns the amperage the controller is allowed to hold given how
    /// close the battery is to the floor. Above `glideBandPct` of headroom
    /// the `candidate` passes through unchanged. Inside the band the
    /// allowance ramps linearly from the full `candidate` at the top down
    /// to `minAmps` at the floor; at or below the floor it pins to
    /// `minAmps`. Never raises the candidate, never goes below `minAmps`.
    ///
    /// - Parameters:
    ///   - candidate: amperage the grid/surplus controller wants this tick.
    ///   - currentBatteryLevel: live battery SoC (%).
    ///   - floorPct: the user's soft floor (%).
    static func glideClampedAmps(
        candidate: Int,
        currentBatteryLevel: Int,
        floorPct: Int,
        minAmps: Int
    ) -> Int {
        let headroom = Double(currentBatteryLevel - floorPct)
        guard headroom < glideBandPct else { return candidate }
        guard headroom > 0 else { return minAmps }
        let frac = headroom / glideBandPct  // (0, 1)
        let allowed = Double(minAmps) + frac * Double(candidate - minAmps)
        return max(minAmps, min(candidate, Int(allowed.rounded())))
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
