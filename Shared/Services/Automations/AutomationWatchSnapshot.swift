internal import Foundation

/// Snapshot of the iOS app's automation + notification state, pushed to
/// the watch via `WCSession.updateApplicationContext` whenever either
/// subsystem changes. Latest-snapshot-wins semantics — the watch always
/// sees the most recent payload, never a partial update.
///
/// Wire format only. The runner classes (`AutomationManager`,
/// `NotificationManager`) stay iOS-only; the watch decodes these structs
/// and renders them, sending commands back via `AutomationWatchCommand`.
///
/// The snapshot deliberately carries **only** what the iPhone exclusively
/// knows — namely the live state of the running automation and the
/// configured notification monitors. Anything the watch can already read
/// on its own through `SolarManager` / `CurrentBuildingState` (charging
/// stations, current battery level, prerequisites flags, …) is
/// intentionally NOT in here, so we don't pay for the redundant WCSession
/// push every time `OverviewData` refreshes on the iPhone side.
struct AutomationWatchSnapshot: Codable, Sendable {
    /// Bumped only on incompatible payload changes. Watch decoder rejects
    /// payloads with an unexpected version (keeps last good snapshot).
    /// V3 added the `notifications` field for story #5.
    var schemaVersion: Int
    var activeAutomation: Automation?
    var state: AutomationState?
    var parameters: AutomationParameters?
    /// Active notification monitors (story #5). Optional so older
    /// iPhones still produce decodable payloads — `nil` reads as "no
    /// notifications, nothing to show."
    var notifications: [NotificationMonitor]?

    static let currentSchemaVersion: Int = 3
}

/// Command sent watch → iOS over WCSession (`sendMessage` when the phone
/// is reachable, queued via `transferUserInfo` otherwise).
enum AutomationWatchCommand: Codable, Sendable {
    case start(automation: Automation, parameters: AutomationParameters)
    case cancel

    // Notifications (story #5)
    case enableNotification(NotificationMonitor)
    case updateNotification(NotificationMonitor)
    case disableNotification(id: UUID)
}

/// Dictionary keys used in the WCSession message / applicationContext
/// payloads. Values are JSON-encoded `Data` blobs.
enum AutomationWCKey {
    static let snapshot = "automation.snapshot.v3"
    static let command = "automation.command.v2"
}
