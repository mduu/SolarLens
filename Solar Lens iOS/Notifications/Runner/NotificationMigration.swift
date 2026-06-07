internal import Foundation

/// One-shot migration of the legacy `Automation.NotifyOnBatteryLevel`
/// persisted state into the new `NotificationManager` store.
///
/// Runs at app launch, **before** `AutomationManager.restorePersistedState`
/// reads the old keys (it can't decode them once we've removed the
/// `NotifyOnBatteryLevel` case from the `Automation` enum). The migration
/// parses the raw `UserDefaults` JSON directly — it deliberately does
/// NOT depend on the post-removal `Automation` / `AutomationState`
/// types so the parse can't break when those types change shape.
///
/// On any decoding failure or malformed payload, the migration silently
/// drops the legacy state. The user loses the running monitor but the
/// app continues to launch. See [ADR-002](../../specs/adrs/002-notifications-separate-from-automations.md).
enum NotificationMigration {

    private static let legacyStateKey = "SolarLens.activeAutomationState"
    private static let legacyParametersKey =
        "SolarLens.activeAutomationParameters"
    private static let migrationDoneKey =
        "SolarLens.notifications.migrationFromAutomationDone.v1"

    /// Run the migration if it hasn't already been done. Idempotent —
    /// once the marker UserDefaults flag is set, subsequent runs are a
    /// no-op.
    @MainActor
    static func runIfNeeded() {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: migrationDoneKey) {
            return
        }
        defer { defaults.set(true, forKey: migrationDoneKey) }

        guard let stateData = defaults.data(forKey: legacyStateKey),
              let stateJson = (try? JSONSerialization.jsonObject(
                with: stateData
              )) as? [String: Any]
        else {
            return
        }

        // Only migrate if the legacy state is a NotifyOnBatteryLevel.
        // The other two cases (BatteryToCar, AutoResetChargingMode)
        // remain in the Automation enum and will decode normally.
        guard let raw = stateJson["automation"] as? String,
              raw == "NotifyOnBatteryLevel"
        else {
            return
        }

        let paramsJson: [String: Any]? = defaults.data(
            forKey: legacyParametersKey
        ).flatMap {
            (try? JSONSerialization.jsonObject(with: $0))
                as? [String: Any]
        }

        let notifyParams =
            (paramsJson?["notifyOnBatteryLevel"] as? [String: Any]) ?? [:]
        let notifyState =
            (stateJson["notifyOnBatteryLevel"] as? [String: Any]) ?? [:]

        let target = (notifyParams["targetBatteryLevel"] as? Int) ?? 80
        let comparisonRaw =
            (notifyParams["comparison"] as? String) ?? "equalOrAbove"
        let comparison: NotificationComparison =
            comparisonRaw == "equalOrBelow" ? .equalOrBelow : .equalOrAbove

        let monitor = NotificationMonitor(
            kind: .BatteryLevel,
            comparison: comparison,
            threshold: target,
            repeatMode: .once,                  // legacy behaviour
            enabledAt: dateFrom(notifyState["startedAt"]) ?? Date(),
            armState: .armed,
            lastValue: notifyState["lastBatteryLevel"] as? Int,
            lastBatteryChargeRate:
                notifyState["lastBatteryChargeRate"] as? Int,
            forecastedTargetAt:
                dateFrom(notifyState["forecastedTargetAt"])
        )

        // Wipe the legacy keys so the now-modified AutomationState can
        // decode cleanly on the next launch.
        defaults.removeObject(forKey: legacyStateKey)
        defaults.removeObject(forKey: legacyParametersKey)

        NotificationManager.shared._replaceForMigration([monitor])

        AutomationLogManager.shared.log(
            .init(
                message: LocalizedStringResource(stringLiteral:
                    "Migrated 'Notify on battery level' automation to the new Notifications subsystem."
                ),
                level: .Info
            )
        )
    }

    /// Decode a JSON-encoded `Date` (Foundation's default is a
    /// `TimeInterval` since 2001) without round-tripping through
    /// `JSONDecoder` (which would require declaring a Codable shape we
    /// otherwise don't need).
    private static func dateFrom(_ raw: Any?) -> Date? {
        guard let interval = raw as? Double else { return nil }
        return Date(timeIntervalSinceReferenceDate: interval)
    }
}
