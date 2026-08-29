internal import Foundation

/// Shared storage for everything the iOS app and the Notification Service
/// Extension both need to see: the active automation's state/parameters and
/// the automation log.
///
/// Background (story #9 / ADR-006): the NSE is a **separate process**. It
/// cannot read `UserDefaults.standard` or the app's Documents directory, so
/// automation state has to live in an App Group container that both processes
/// are entitled to.
///
/// The store degrades gracefully: as long as the App Group entitlement is not
/// present (older builds, or before the capability is configured), everything
/// falls back to the app-local locations that were used before, so no
/// behaviour changes and nothing is lost. `isShared` reports which mode is
/// active.
///
/// This type lives in `Shared/` and is therefore compiled for iOS, watchOS and
/// tvOS — it must stay dependency-free (Foundation only).
enum AutomationSharedStore {

    /// App Group shared by the iOS app, the Notification Service Extension and
    /// (optionally) the widget / Live Activity extensions.
    static let appGroupIdentifier =
        "group.com.marcduerst.SolarManagerWatch"

    // MARK: - Availability

    /// Container URL of the App Group, or `nil` when the entitlement is not
    /// granted to this target/build. `FileManager` is the honest probe here —
    /// `UserDefaults(suiteName:)` may hand back an object that silently fails
    /// to persist.
    static var containerURL: URL? {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        )
    }

    /// `true` when state is really shared across processes (App Group
    /// available), `false` while running in the app-local fallback.
    static var isShared: Bool { containerURL != nil }

    // MARK: - Key-value storage

    /// `UserDefaults` suite backed by the App Group, or `.standard` when the
    /// group is unavailable.
    static var defaults: UserDefaults {
        guard containerURL != nil,
            let suite = UserDefaults(suiteName: appGroupIdentifier)
        else {
            return .standard
        }
        return suite
    }

    // MARK: - File storage

    /// Directory for shared files (automation log). Falls back to the app's
    /// Documents directory when the App Group is unavailable — which is
    /// exactly where the log lived before story #9.
    static var filesDirectory: URL {
        guard let containerURL else { return legacyFilesDirectory }
        return containerURL
    }

    /// Pre-story-#9 location of file-based state: the app's Documents
    /// directory. Kept for migration and as the fallback.
    static var legacyFilesDirectory: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
    }

    /// Shared URL for a file that used to live in the Documents directory.
    static func fileURL(_ name: String) -> URL {
        filesDirectory.appendingPathComponent(name)
    }

    static func legacyFileURL(_ name: String) -> URL {
        legacyFilesDirectory.appendingPathComponent(name)
    }

    // MARK: - Migration

    /// Marks a one-shot migration as done, so it never runs twice. Stored in
    /// the *shared* defaults so both processes agree.
    private static let migrationFlagPrefix = "SolarLens.migratedToAppGroup."

    /// Moves a `UserDefaults` value from `.standard` into the shared suite,
    /// once. No-op when the App Group is unavailable (the fallback *is*
    /// `.standard`), when the migration already ran, or when there is nothing
    /// to move.
    ///
    /// The legacy value is intentionally **left in place**: if the user
    /// downgrades to an older build, their running automation still restores.
    /// Once the new build has written state at least once, the shared copy is
    /// authoritative.
    static func migrateDefaultsKeyIfNeeded(_ key: String) {
        guard isShared else { return }
        let flag = migrationFlagPrefix + key
        let shared = defaults
        guard !shared.bool(forKey: flag) else { return }
        defer { shared.set(true, forKey: flag) }

        guard shared.object(forKey: key) == nil,
            let legacy = UserDefaults.standard.object(forKey: key)
        else { return }
        shared.set(legacy, forKey: key)
    }

    /// Copies a file from the Documents directory into the shared container,
    /// once, if the shared copy does not exist yet.
    static func migrateFileIfNeeded(_ name: String) {
        guard isShared else { return }
        let flag = migrationFlagPrefix + "file." + name
        let shared = defaults
        guard !shared.bool(forKey: flag) else { return }
        defer { shared.set(true, forKey: flag) }

        let target = fileURL(name)
        let source = legacyFileURL(name)
        let fm = FileManager.default
        guard !fm.fileExists(atPath: target.path),
            fm.fileExists(atPath: source.path)
        else { return }
        try? fm.copyItem(at: source, to: target)
    }
}

// MARK: - Tick lease

extension AutomationSharedStore {

    private static let leaseKey = "SolarLens.automationTickLease"

    /// Cooperative lease so the app process and the Notification Service
    /// Extension never execute the same automation tick concurrently — that
    /// would fire the charging-mode API call twice.
    ///
    /// Deliberately simple: a timestamp in shared `UserDefaults`. There is no
    /// cross-process atomic compare-and-swap available here, and the race
    /// window (two writers within microseconds) is far narrower than the real
    /// case we defend against (the app foregrounded while a push arrives).
    /// The API call itself is idempotent in effect — setting the same charging
    /// mode twice is harmless — so a best-effort lease is the right trade.
    ///
    /// - Parameter duration: how long the lease is held before it is
    ///   considered abandoned (a crashed NSE must not block the app forever).
    /// - Returns: `true` when the caller may run the tick.
    static func acquireTickLease(
        for duration: TimeInterval = 45
    ) -> Bool {
        let store = defaults
        let now = Date()
        if let until = store.object(forKey: leaseKey) as? Date, until > now {
            return false
        }
        store.set(now.addingTimeInterval(duration), forKey: leaseKey)
        return true
    }

    static func releaseTickLease() {
        defaults.removeObject(forKey: leaseKey)
    }
}

// MARK: - Well-known names & active automation

extension AutomationSharedStore {

    /// File name of the automation log inside the shared container.
    static let logFileName = "automation-logs.json"

    /// `UserDefaults` keys the app's `AutomationManager` persists under.
    /// Named here because the Notification Service Extension reads and clears
    /// the same records.
    static let activeStateKey = "SolarLens.activeAutomationState"
    static let activeParametersKey = "SolarLens.activeAutomationParameters"

    /// Identifier of the local "reset is due" notification the app schedules
    /// as a fallback. The extension removes it once it has done the work for
    /// real, so the user never sees both.
    static let resetDueFallbackNotificationId =
        "automation.autoResetChargingMode.due"

    /// The automation the app currently has running, as persisted. `nil` when
    /// nothing is running (or the run already finished).
    static var activeState: AutomationState? {
        guard let data = defaults.data(forKey: activeStateKey) else {
            return nil
        }
        return try? JSONDecoder().decode(AutomationState.self, from: data)
    }

    static var activeParameters: AutomationParameters? {
        guard let data = defaults.data(forKey: activeParametersKey) else {
            return nil
        }
        return try? JSONDecoder().decode(
            AutomationParameters.self,
            from: data
        )
    }

    /// Clears the persisted run. Used by the extension after it executed a
    /// deadline, so the app does not run the same automation again.
    static func clearActiveAutomation() {
        let store = defaults
        store.removeObject(forKey: activeStateKey)
        store.removeObject(forKey: activeParametersKey)
    }
}
