internal import Foundation

struct AutomationNotifyOnBatteryLevelParameters: Codable, Sendable {
    /// Target battery level (0–100).
    var targetBatteryLevel: Int = 80
    var comparison: NotifyOnBatteryLevelPayload.Comparison = .equalOrAbove

    init() {}

    init(
        targetBatteryLevel: Int,
        comparison: NotifyOnBatteryLevelPayload.Comparison
    ) {
        self.targetBatteryLevel = targetBatteryLevel
        self.comparison = comparison
    }
}

enum AutomationNotifyOnBatteryLevelStopReason: String, Codable, Sendable {
    case conditionMet
    case timedOut
    case cancelled
}

struct AutomationNotifyOnBatteryLevelState: Codable, Sendable {
    var isStarted: Bool = false
    var startedAt: Date? = nil
    var lastTickAt: Date? = nil
    var lastBatteryLevel: Int? = nil
    /// Most recent house-battery charge rate (W). Positive = charging,
    /// negative = discharging, near-zero = idle. Used by the UI to
    /// explain why a forecast isn't available (idle / wrong direction).
    var lastBatteryChargeRate: Int? = nil
    var stopReason: AutomationNotifyOnBatteryLevelStopReason? = nil
    /// Most recent linear forecast for when the battery hits the
    /// user-set threshold. Refreshed each tick. `nil` if no forecast
    /// is possible (battery idle, wrong direction, no telemetry yet).
    var forecastedTargetAt: Date? = nil

    init() {}
}
