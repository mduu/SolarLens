internal import Foundation

final class AutomationLogManager {
    static let shared = AutomationLogManager()

    private init() {
        // Pre-story-#9 the log lived in the app's Documents directory; move
        // it into the App Group once so the Notification Service Extension
        // appends to the log the user already knows.
        AutomationSharedStore.migrateFileIfNeeded(
            AutomationSharedStore.logFileName
        )
    }

    // Append a new entry
    func log(
        _ message: AutomationLogMessage
    ) {
        let entry = AutomationLogWriter.append(message)
        NotificationCenter.default
            .post(name: .automationLogAdded, object: entry)
    }

    /// Load all entries from disk
    func load() -> [AutomationLogMessage] {
        AutomationLogWriter.load()
    }

    func clearAll() -> Void {
        AutomationLogWriter.save([])
        NotificationCenter.default
            .post(name: .automationLogCleared, object: nil)
    }
}

extension Notification.Name {
    static let automationLogAdded = Notification.Name("automationLogAdded")
    static let automationLogCleared = Notification.Name("automationLogCleared")
}
