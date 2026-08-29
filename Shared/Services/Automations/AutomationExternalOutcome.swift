internal import Foundation

/// Result of an automation run that was executed **outside the app process** —
/// today only by the Notification Service Extension when the server's
/// scheduled push arrives (story #9 / ADR-006).
///
/// The extension cannot touch the Live Activity, the in-app log views or the
/// observable `AutomationManager`. So it does three things: apply the change,
/// clear the shared active state, and leave this record behind. The app picks
/// it up the next time it runs (`AutomationManager.adoptExternalCompletion`),
/// finishes the local teardown, and drops the record.
struct AutomationExternalOutcome: Codable, Sendable, Equatable {

    enum Kind: String, Codable, Sendable {
        /// After-reset charging mode was applied successfully.
        case applied
        /// User had changed the mode manually — the station was left alone.
        case userOverride
        /// Applying the mode failed.
        case failed
    }

    var automation: Automation
    var kind: Kind
    var at: Date
    /// Human-readable detail, already localized by the extension: the applied
    /// mode's title, the mode the user had selected, or the error message.
    var detail: String?
    /// Set when the run switched the charging station's mode, so the app can
    /// apply an optimistic UI override instead of waiting for the backend.
    var chargingStationId: String?
    var chargingModeRaw: Int?

    init(
        automation: Automation,
        kind: Kind,
        at: Date = Date(),
        detail: String? = nil,
        chargingStationId: String? = nil,
        chargingModeRaw: Int? = nil
    ) {
        self.automation = automation
        self.kind = kind
        self.at = at
        self.detail = detail
        self.chargingStationId = chargingStationId
        self.chargingModeRaw = chargingModeRaw
    }
}

extension AutomationSharedStore {

    private static let externalOutcomeKey =
        "SolarLens.automationExternalOutcome"

    /// Written by the Notification Service Extension, consumed by the app.
    static var externalOutcome: AutomationExternalOutcome? {
        get {
            guard let data = defaults.data(forKey: externalOutcomeKey) else {
                return nil
            }
            return try? JSONDecoder().decode(
                AutomationExternalOutcome.self,
                from: data
            )
        }
        set {
            guard let newValue,
                let data = try? JSONEncoder().encode(newValue)
            else {
                defaults.removeObject(forKey: externalOutcomeKey)
                return
            }
            defaults.set(data, forKey: externalOutcomeKey)
        }
    }
}
