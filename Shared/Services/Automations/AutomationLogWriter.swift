internal import Foundation

/// Append-only writer for the automation log, usable from **any** process.
///
/// The Notification Service Extension writes into the same log the user reads
/// in `AutomationLogView` (story #9 / ADR-006), so the storage layer has to
/// live outside the app-only `AutomationLogManager` — which keeps the
/// observable/`NotificationCenter` half and delegates the file work here.
///
/// Deliberately simple: read-modify-write of a small JSON array under a
/// coordinated file lock. The log sees a handful of entries per tick, and the
/// only concurrent writers are the app and one extension.
enum AutomationLogWriter {

    static var fileURL: URL {
        AutomationSharedStore.fileURL(AutomationSharedStore.logFileName)
    }

    static func load() -> [AutomationLogMessage] {
        guard let data = try? Data(contentsOf: fileURL),
            let entries = try? JSONDecoder().decode(
                [AutomationLogMessage].self,
                from: data
            )
        else { return [] }
        return entries
    }

    static func save(_ entries: [AutomationLogMessage]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    @discardableResult
    static func append(
        _ message: AutomationLogMessage
    ) -> AutomationLogMessage {
        var entries = load()
        entries.append(message)
        save(entries)
        return message
    }

    /// Convenience for callers outside the app that only have a plain string
    /// (the extension builds its messages at runtime).
    static func append(_ message: String, level: AutomationLogMessageLevel) {
        append(
            AutomationLogMessage(
                message: LocalizedStringResource(stringLiteral: message),
                level: level
            )
        )
    }
}
