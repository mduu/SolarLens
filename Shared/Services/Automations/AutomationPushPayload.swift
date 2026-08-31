internal import Foundation

/// Payload contract between the server's wake scheduler and the device.
///
/// The server only echoes back what the app registered — it never knows what an
/// automation does.
///
/// ```json
/// {
///   "aps": { "alert": { … }, "mutable-content": 1 },
///   "solarlens": { "kind": "automation-deadline",
///                  "automation": "AutoResetChargingMode",
///                  "scheduleId": "9F2C…" },
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

    /// Unknown kinds must be delivered untouched — a newer server may send kinds
    /// this build does not know.
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
