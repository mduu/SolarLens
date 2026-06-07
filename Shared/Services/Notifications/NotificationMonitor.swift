public import Foundation

/// Above/below comparator for a notification's threshold check.
public enum NotificationComparison: String, Codable, Hashable, Sendable {
    case equalOrAbove
    case equalOrBelow
}

/// Whether a monitor notifies once and ends, or keeps watching for the
/// condition to re-occur (with hysteresis re-arm — see story #5).
public enum NotificationRepeatMode: String, Codable, Hashable, Sendable {
    case once
    case everyReoccurrence
}

/// Re-arm state for repeating monitors. Single-fire monitors stay in
/// `.armed` until they fire, then end.
public enum NotificationArmState: String, Codable, Hashable, Sendable {
    /// Watching the value; will fire on the next threshold crossing.
    case armed
    /// Already fired; waiting for the value to clearly leave the
    /// threshold (hysteresis deadband + dwell) before re-arming.
    case firedWaitingForReset
}

/// One configured notification monitor — user-set config plus the
/// runtime fields the manager updates on each tick.
///
/// Lives in `Shared/` so the watchOS app can decode it when the iPhone
/// pushes the list over WatchConnectivity. Identifiable by `id` so
/// SwiftUI lists can render rows and the manager can look up monitors
/// by id when the user disables/edits one.
public struct NotificationMonitor: Codable, Hashable, Sendable, Identifiable {

    public var id: UUID

    // MARK: - User-set config

    public var kind: SolarLensNotification
    public var comparison: NotificationComparison

    /// Threshold expressed in the monitor's canonical unit:
    /// - `BatteryLevel`: percent (0–100)
    /// - kW monitors: **watts** (matches the `OverviewData` fields,
    ///   which are all `Int` watts). The setup sheet converts to/from
    ///   kW for display.
    public var threshold: Int

    public var repeatMode: NotificationRepeatMode

    /// When this monitor was first enabled. Drives the "running for Xm"
    /// label on the running card / row.
    public var enabledAt: Date

    // MARK: - Runtime state

    /// Hysteresis state. Single-fire monitors finish from `.armed`;
    /// repeating monitors loop `.armed → .firedWaitingForReset → .armed`.
    public var armState: NotificationArmState

    /// Last value the monitor observed, in canonical units.
    public var lastValue: Int?

    /// Last time the monitor ticked.
    public var lastCheckAt: Date?

    /// Next time the manager should tick this monitor.
    public var nextCheckAt: Date?

    /// Most recent fire — used for "Last fired X ago" UX and to throttle
    /// re-fires when somehow the dwell timer is missed.
    public var lastFiredAt: Date?

    /// How many times this monitor has fired since it was enabled.
    /// Cosmetic.
    public var fireCount: Int

    // MARK: - Battery-level extras (used only by `BatteryLevel`)

    /// Most recent house-battery charge rate, watts. Positive = charging,
    /// negative = discharging. Drives the forecast extrapolation.
    public var lastBatteryChargeRate: Int?

    /// Linear-extrapolated time at which the threshold is forecast to be
    /// crossed. Used to schedule a calendar-triggered "backstop"
    /// notification so the user is alerted at the predicted moment even
    /// if iOS doesn't grant BG runtime.
    public var forecastedTargetAt: Date?

    public init(
        id: UUID = UUID(),
        kind: SolarLensNotification,
        comparison: NotificationComparison,
        threshold: Int,
        repeatMode: NotificationRepeatMode = .once,
        enabledAt: Date,
        armState: NotificationArmState = .armed,
        lastValue: Int? = nil,
        lastCheckAt: Date? = nil,
        nextCheckAt: Date? = nil,
        lastFiredAt: Date? = nil,
        fireCount: Int = 0,
        lastBatteryChargeRate: Int? = nil,
        forecastedTargetAt: Date? = nil
    ) {
        self.id = id
        self.kind = kind
        self.comparison = comparison
        self.threshold = threshold
        self.repeatMode = repeatMode
        self.enabledAt = enabledAt
        self.armState = armState
        self.lastValue = lastValue
        self.lastCheckAt = lastCheckAt
        self.nextCheckAt = nextCheckAt
        self.lastFiredAt = lastFiredAt
        self.fireCount = fireCount
        self.lastBatteryChargeRate = lastBatteryChargeRate
        self.forecastedTargetAt = forecastedTargetAt
    }
}

extension NotificationMonitor {

    /// Did the observed `value` (in canonical units) satisfy the user's
    /// threshold condition? Pure.
    public func conditionMet(value: Int) -> Bool {
        switch comparison {
        case .equalOrAbove: return value >= threshold
        case .equalOrBelow: return value <= threshold
        }
    }

    /// Hysteresis: did the observed `value` clearly leave the threshold
    /// on the OPPOSITE side, far enough to count as a real reset (not
    /// just sensor noise / flapping)?
    ///
    /// For the threshold `T` with comparator `≥`, this asks "is the
    /// value comfortably **below** `T − deadband` now?" — and vice
    /// versa. The deadband is computed by [`hysteresisDeadband`].
    public func conditionResetMet(value: Int) -> Bool {
        let deadband = hysteresisDeadband
        switch comparison {
        case .equalOrAbove: return value < (threshold - deadband)
        case .equalOrBelow: return value > (threshold + deadband)
        }
    }

    /// Per-kind deadband, in canonical units (percent or watts).
    /// Chosen to be "clearly not flapping" rather than "exactly N units":
    ///
    /// - **Percent** (`BatteryLevel`): 5 % — battery readings round to
    ///   whole percents and a 1–2 % wobble is normal; 5 % means the
    ///   battery has actually moved.
    /// - **kW** monitors: max(10 % of threshold, 200 W). 200 W is the
    ///   noise floor of the Solar Manager grid readings; 10 % handles
    ///   higher-power thresholds (a 5 kW threshold needs 500 W to count
    ///   as "really left").
    public var hysteresisDeadband: Int {
        switch kind {
        case .BatteryLevel:
            return 5  // percent
        default:
            let pct = max(1, abs(threshold) / 10)  // 10 % of threshold
            return max(pct, 200)                   // floor at 200 W
        }
    }
}
