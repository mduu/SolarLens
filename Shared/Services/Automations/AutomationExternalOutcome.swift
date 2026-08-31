internal import Foundation

/// Result of a run the Notification Service Extension executed while the app was
/// suspended or force-quit.
///
/// The extension cannot touch the Live Activity or the observable manager, so it
/// leaves this behind; the app finishes the teardown on its next run
/// (`AutomationManager.adoptExternalCompletionIfNeeded`).
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
