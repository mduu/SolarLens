public import Foundation

/// Identifier for the **read-only monitors** Solar Lens can run in parallel.
///
/// Lives in `Shared/` so the watchOS app can decode `NotificationMonitor`
/// payloads pushed from the iPhone over WatchConnectivity. Named
/// `SolarLensNotification` (not just `Notification`) to avoid clashing
/// with `Foundation.Notification`.
///
/// A notification is conceptually trivial: a polling cadence and a
/// "value compared against threshold" predicate. See [ADR-002](
/// ../adrs/002-notifications-separate-from-automations.md) for the
/// reasoning behind keeping these separate from `Automation`.
public enum SolarLensNotification: String, Codable, Hashable, Sendable,
    CaseIterable, Identifiable
{
    public var id: String { rawValue }

    /// House battery state of charge, in percent (0–100).
    case BatteryLevel

    /// Instantaneous solar production, in watts. (UI displays kW.)
    case SolarProduction

    /// Instantaneous solar-to-grid export, in watts.
    case GridExport

    /// Instantaneous grid-to-house import, in watts.
    case GridImport

    /// Instantaneous overall house consumption, in watts.
    case OverallConsumption

    /// Sum of `currentPower` across all charging stations, in watts.
    case ChargingThroughput
}

extension SolarLensNotification {

    /// SF Symbol used in the notifications list, setup sheet, and the
    /// in-flight delivered notification.
    public var iconSystemName: String {
        switch self {
        case .BatteryLevel:        return "bolt.batteryblock.fill"
        case .SolarProduction:     return "sun.max.fill"
        case .GridExport:          return "arrow.up.right.circle.fill"
        case .GridImport:          return "arrow.down.right.circle.fill"
        case .OverallConsumption:  return "house.fill"
        case .ChargingThroughput:  return "bolt.car.fill"
        }
    }

    /// Whether the threshold value is a percentage (`true`) or a watt
    /// reading the UI should display as kW (`false`).
    public var isPercent: Bool {
        switch self {
        case .BatteryLevel: return true
        default: return false
        }
    }

    /// Title used in cards, sheets, and the delivered notification.
    public var localizedTitleKey: String.LocalizationValue {
        switch self {
        case .BatteryLevel:        return "Battery level"
        case .SolarProduction:     return "Solar production"
        case .GridExport:          return "Grid export"
        case .GridImport:          return "Grid import"
        case .OverallConsumption:  return "Overall consumption"
        case .ChargingThroughput:  return "Charging throughput"
        }
    }

    /// Short description shown on the idle card / setup-sheet footer.
    public var localizedDescriptionKey: String.LocalizationValue {
        switch self {
        case .BatteryLevel:
            return "Notify when the house battery reaches a level you choose."
        case .SolarProduction:
            return "Notify when current solar production crosses a level you choose."
        case .GridExport:
            return "Notify when energy fed back into the grid crosses a level you choose."
        case .GridImport:
            return "Notify when energy drawn from the grid crosses a level you choose."
        case .OverallConsumption:
            return "Notify when the home's total consumption crosses a level you choose."
        case .ChargingThroughput:
            return "Notify when the combined power going into your car(s) crosses a level you choose."
        }
    }
}
