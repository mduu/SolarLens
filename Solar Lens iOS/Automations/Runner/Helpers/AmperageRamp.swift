internal import Foundation

enum AmperageRamp {
    /// Default grid grace band in Watts. See story #3 → "Grace band sizing".
    static let defaultGraceW = 200

    /// Headroom margin we keep on top of the next ramp-up step when using
    /// battery-headroom (not grid-export) as the ramp-up cue. This buffers
    /// against a small load kicking in between ticks and turning a balanced
    /// state into grid import.
    /// 1 step ≈ 690 W on 3-phase, so a 2×-step margin tolerates one
    /// fridge/heat-pump/circulator turning on without overshoot.
    static let batteryHeadroomMarginSteps = 2

    /// Bounds for accepting a live W/A observation as plausible. Below the
    /// lower bound we'd react to noise; above the upper we'd attribute
    /// transient inrush spikes to steady draw.
    static let minObservedWattsPerAmp: Double = 180
    static let maxObservedWattsPerAmp: Double = 760

    /// EWMA threshold above which we treat the run as being in a slow
    /// regime (iOS BG-throttling territory). When ticks are coming in
    /// less often than this, the wallbox can drain the battery for many
    /// minutes between checks — so we cap and progressively halve
    /// amperage until the EWMA recovers (typically when the user
    /// foregrounds the app and a real tick fires).
    static let slowTickThresholdMinutes: Double = 5.0

    struct Inputs {
        let currentAmps: Int
        let gridImportW: Int
        let gridExportW: Int
        /// Signed battery flow: positive = battery charging (PV surplus),
        /// negative = battery discharging into loads.
        let batteryChargeRateW: Int
        let batteryMaxDischargeW: Int
        let phases: WallboxPhases
        /// Live W/A observed at the wallbox: `station.currentPower /
        /// currentAmps`. Pass `nil` if unavailable (e.g. first tick or
        /// wallbox not yet drawing). Used only when `phases == .auto`.
        let observedWattsPerAmp: Double?
        let graceW: Int
        /// EWMA of the recent observed tick interval (in minutes). Drives
        /// the BG-throttling-aware ramp-down. Pass the value the runner
        /// already maintains in `AutomationBatteryToCarState`.
        let smoothedTickIntervalMinutes: Double
    }

    /// Decide the next `constantCurrentSetting` in amps.
    ///
    /// Decision tree (asymmetric, conservative):
    /// - grid import > graceW             → ramp DOWN by enough amps to absorb it
    /// - grid import > 0 (in band)        → HOLD; never ramp up while any import exists
    /// - grid export > one A-step         → ramp UP (true surplus to redirect)
    /// - both grid flows ≤ graceW (balanced):
    ///     - battery is charging          → ramp UP (PV surplus is being
    ///                                       absorbed into the battery —
    ///                                       redirect into the EV instead;
    ///                                       this is exactly the goal of
    ///                                       Battery → Car)
    ///     - battery is discharging AND has > 2 A-steps of headroom on top
    ///       of the next step             → ramp UP
    /// - otherwise                        → HOLD
    ///
    /// **BG-aware clamp**: if `smoothedTickIntervalMinutes` is above the
    /// slow-regime threshold, the result is additionally clamped to at
    /// most `currentAmps / 2` (and never below `minAmps`). This trims
    /// the wallbox draw progressively when iOS isn't letting us re-tick
    /// in a timely fashion, so a long unmonitored sleep can't drain the
    /// battery past the soft floor.
    ///
    /// Output is clamped to 6–32 A (Solar Manager protocol range).
    static func compute(_ input: Inputs) -> Int {
        let stepW = effectiveStepW(input)
        let dischargeW = max(0, -input.batteryChargeRateW)
        let chargingW = max(0, input.batteryChargeRateW)
        var deltaA = 0

        if input.gridImportW > input.graceW {
            deltaA = -max(1, Int(ceil(Double(input.gridImportW) / stepW)))
        } else if input.gridImportW > 0 {
            deltaA = 0
        } else if Double(input.gridExportW) > stepW {
            deltaA = 1
        } else if input.gridExportW <= input.graceW {
            // Grid effectively flat in both directions.
            if chargingW > 0 {
                // PV surplus is being absorbed by the battery — that's the
                // exact energy we want flowing into the EV instead. Ramp up.
                deltaA = 1
            } else if dischargeW > 0 {
                // Battery actively discharging — only ramp up if we have buffer.
                let batteryHeadroomW = max(
                    0, input.batteryMaxDischargeW - dischargeW
                )
                let requiredHeadroomW =
                    stepW * Double(batteryHeadroomMarginSteps + 1)
                if Double(batteryHeadroomW) > requiredHeadroomW {
                    deltaA = 1
                }
            }
        }

        let candidate = max(
            PowerToAmps.minAmps,
            min(PowerToAmps.maxAmps, input.currentAmps + deltaA)
        )

        return applyBackgroundThrottlingClamp(candidate: candidate, input: input)
    }

    /// Cap the controller's output when the EWMA tick interval shows we
    /// are flying blind. Halves towards `minAmps` on each subsequent
    /// slow tick so a stuck-in-background run dials itself down rather
    /// than holding 16 A while iOS sleeps the app for half an hour.
    private static func applyBackgroundThrottlingClamp(
        candidate: Int,
        input: Inputs
    ) -> Int {
        guard
            input.smoothedTickIntervalMinutes > slowTickThresholdMinutes
        else {
            return candidate
        }
        let halved = max(PowerToAmps.minAmps, input.currentAmps / 2)
        return min(candidate, halved)
    }

    /// Returns whether the BG-throttling clamp would change the result
    /// on this tick — useful for logging "why did the controller drop
    /// from 12 A to 6 A?" without recomputing the whole rule.
    static func backgroundThrottlingActive(
        smoothedTickIntervalMinutes: Double
    ) -> Bool {
        smoothedTickIntervalMinutes > slowTickThresholdMinutes
    }

    static func effectiveStepW(_ input: Inputs) -> Double {
        guard input.phases == .auto else {
            return input.phases.fallbackWattsPerAmp
        }
        if let obs = input.observedWattsPerAmp,
           (minObservedWattsPerAmp...maxObservedWattsPerAmp).contains(obs) {
            return obs
        }
        return input.phases.fallbackWattsPerAmp
    }
}
