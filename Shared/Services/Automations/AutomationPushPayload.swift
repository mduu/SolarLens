internal import Foundation

/// Contract between the Solar Lens server's wake scheduler and the app /
/// Notification Service Extension (story #9).
///
/// The server never knows *what* an automation does — it only echoes back the
/// opaque values the app registered with the schedule. Everything here is
/// therefore either a routing hint (`kind`) or a value the device itself
/// provided (`automation`, `scheduleId`).
///
/// Example alert payload (deadline):
/// ```json
/// {
///   "aps": {
///     "alert": { "title": "…", "body": "…" },
///     "mutable-content": 1,
///     "sound": "default",
///     "interruption-level": "time-sensitive"
///   },
///   "solarlens": {
///     "kind": "automation-deadline",
///     "automation": "AutoResetChargingMode",
///     "scheduleId": "9F2C…"
///   },
///   "deepLink": "solarlens://automations"
/// }
/// ```
enum AutomationPushPayload {

    /// Top-level key carrying our own routing dictionary, so we never collide
    /// with Apple's `aps` keys.
    static let rootKey = "solarlens"

    enum Key {
        static let kind = "kind"
        static let automation = "automation"
        static let scheduleId = "scheduleId"
    }

    /// What the push is for. Anything unknown must be delivered unchanged —
    /// a future server version may send kinds this build does not handle.
    enum Kind: String, Sendable {
        /// Visible alert push at a time-bound automation's end time. The
        /// Notification Service Extension executes the automation and rewrites
        /// the notification text with the real outcome.
        case automationDeadline = "automation-deadline"
        /// Silent push used as an extra background wake source. Never reaches
        /// the extension (no `mutable-content`), handled by the app delegate.
        case wake = "wake"
    }

    /// Parsed view over a notification's `userInfo`.
    struct Parsed: Sendable {
        var kind: Kind?
        var automation: Automation?
        var scheduleId: String?
    }

    static func parse(userInfo: [AnyHashable: Any]) -> Parsed {
        guard let root = userInfo[rootKey] as? [String: Any] else {
            return Parsed()
        }
        let kind = (root[Key.kind] as? String).flatMap(Kind.init(rawValue:))
        let automation = (root[Key.automation] as? String)
            .flatMap(Automation.init(rawValue:))
        return Parsed(
            kind: kind,
            automation: automation,
            scheduleId: root[Key.scheduleId] as? String
        )
    }
}
