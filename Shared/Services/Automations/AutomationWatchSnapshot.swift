internal import Foundation

/// Snapshot of the iOS app's automation state, pushed to the watch via
/// `WCSession.updateApplicationContext` whenever anything relevant
/// changes. Latest-snapshot-wins semantics — the watch always sees the
/// most recent payload, never a partial update.
///
/// Wire format only. The runner classes stay iOS-only; the watch decodes
/// these structs and renders them, sending commands back via
/// `AutomationWatchCommand`.
struct AutomationWatchSnapshot: Codable, Sendable {
    /// Bumped only on incompatible payload changes. Watch decoder rejects
    /// payloads with an unexpected version (keeps last good snapshot).
    var schemaVersion: Int
    var lastUpdated: Date
    var activeAutomation: Automation?
    var state: AutomationState?
    var parameters: AutomationParameters?
    var prerequisites: Prerequisites
    /// Charging-station metadata for the watch setup sheets.
    var chargingStations: [WatchChargingStation]
    /// Current battery level (0–100) for the NotifyOnBatteryLevel setup
    /// sheet hint. `nil` when no battery sensor is reporting.
    var currentBatteryLevel: Int?

    static let currentSchemaVersion: Int = 1

    struct Prerequisites: Codable, Sendable {
        var hasAnyBattery: Bool
        var hasAnyCarChargingStation: Bool
    }

    /// Lightweight DTO for the watch setup sheets — the full
    /// `ChargingStation` is `@Observable` and not `Sendable`, and the
    /// watch only needs `id` + `name` to populate pickers.
    struct WatchChargingStation: Codable, Sendable, Identifiable, Hashable {
        var id: String
        var name: String
    }
}

/// Command sent watch → iOS over WCSession (`sendMessage` when the phone
/// is reachable, queued via `transferUserInfo` otherwise).
enum AutomationWatchCommand: Codable, Sendable {
    case start(automation: Automation, parameters: AutomationParameters)
    case cancel
}

/// Dictionary keys used in the WCSession message / applicationContext
/// payloads. Values are JSON-encoded `Data` blobs.
enum AutomationWCKey {
    static let snapshot = "automation.snapshot.v1"
    static let command = "automation.command.v1"
}
