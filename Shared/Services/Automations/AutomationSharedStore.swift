internal import Foundation

/// State the app and the Notification Service Extension both need: the active
/// automation, its parameters and the automation log.
///
/// They are separate processes, so this lives in an App Group container. Without
/// the entitlement everything falls back to the app-local locations used before
/// story #9, so nothing breaks — `isShared` tells which mode is active.
enum AutomationSharedStore {

    /// App Group shared by the iOS app, the Notification Service Extension and
    /// (optionally) the widget / Live Activity extensions.
    static let appGroupIdentifier =
        "group.com.marcduerst.SolarManagerWatch"

    // MARK: - Availability

    /// `nil` when the entitlement is missing. `FileManager` is the honest probe —
    /// `UserDefaults(suiteName:)` can hand back an object that silently fails to
    /// persist.
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

    /// Copies a pre-story-#9 value into the shared suite, once.
    ///
    /// The legacy value stays behind on purpose: after a downgrade the old build
    /// still finds its running automation.
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

    /// Cooperative lease so the app and the extension never run the same tick at
    /// once and call the charging-mode API twice.
    ///
    /// A timestamp is enough: there is no cross-process compare-and-swap here, the
    /// real race (app foregrounded while a push arrives) is far wider than the
    /// microseconds this misses, and setting the same mode twice is harmless.
    ///
    /// - Parameter duration: after this the lease is treated as abandoned, so a
    ///   crashed extension cannot block the app forever.
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
