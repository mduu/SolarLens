public import Foundation

/// Snapshot of the Notify-on-Battery-Level automation, sized for the Live
/// Activity content budget. The LA renders the current battery level and
/// the user-set threshold; the actual condition check still happens on
/// every monitor tick inside the runner.
public struct NotifyOnBatteryLevelPayload: Codable, Hashable {
    /// Comparison the user picked. Stored as a raw string so both app and
    /// widget extension targets agree on the wire format.
    public enum Comparison: String, Codable, Hashable {
        case equalOrAbove
        case equalOrBelow
    }

    /// Target battery level (percent, 0–100) the user wants to be
    /// notified about.
    public var targetBatteryLevel: Int

    /// Whether the notification should fire when battery is at-or-above
    /// or at-or-below the target.
    public var comparison: Comparison

    /// Last battery level we observed for the house battery, in percent.
    /// `nil` before the first telemetry fetch completes.
    public var lastBatteryLevel: Int?

    /// When the run started — drives "running for Xm" in the LA.
    public var startedAt: Date

    public init(
        targetBatteryLevel: Int,
        comparison: Comparison,
        lastBatteryLevel: Int?,
        startedAt: Date
    ) {
        self.targetBatteryLevel = targetBatteryLevel
        self.comparison = comparison
        self.lastBatteryLevel = lastBatteryLevel
        self.startedAt = startedAt
    }
}
