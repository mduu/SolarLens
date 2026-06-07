/// Identifier for the on-device automations Solar Lens can run.
///
/// Lives in `Shared/` so the iOS Live Activity widget extension can use it
/// alongside the iOS app. The `getAutomationTask()` extension that maps a
/// case to its `AutomationTask` lives in the iOS app target only —
/// `AutomationTask` and the runner are not shared.
///
/// Notifications (read-only monitors that poll a value and post a local
/// notification) used to live here too as `NotifyOnBatteryLevel`. They
/// have been extracted into their own subsystem — see
/// [ADR-002](../../specs/adrs/002-notifications-separate-from-automations.md)
/// and [story #5](../../specs/stories/005-introduce-notifications.md).
public enum Automation: String, Codable, Hashable, Sendable {
    case BatteryToCar
    case AutoResetChargingMode
}

extension Automation {

    /// SF Symbol used everywhere the automation is represented at a glance:
    /// the Automation tab badge, the running-card status pill, the Lock
    /// Screen Live Activity card header, and the Dynamic Island compact
    /// leading slot.
    public var liveActivityIconSystemName: String {
        switch self {
        case .BatteryToCar:
            return "bolt.car.circle.fill"
        case .AutoResetChargingMode:
            return "timer.circle.fill"
        }
    }
}
