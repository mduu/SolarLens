internal import Foundation

final class AutomationLogManager {
    static let shared = AutomationLogManager()

    private let fileURL: URL = {
        let dir = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
        return dir.appendingPathComponent("automation-logs.json")
    }()

    // Append a new entry
    func log(
        _ message: AutomationLogMessage
    ) {
        var logs = load()
        logs.append(message)
        save(logs)
        NotificationCenter.default
            .post(name: .automationLogAdded, object: logs.last)
    }
    
    /// Load all entries from disk
    func load() -> [AutomationLogMessage] {
        guard let data = try? Data(contentsOf: fileURL),
            let entries = try? JSONDecoder().decode(
                [AutomationLogMessage].self,
                from: data
            )
        else { return [] }
        
        return entries
    }
    
    func clearAll() -> Void {
        save([])
        NotificationCenter.default
            .post(name: .automationLogCleared, object: nil)

    }

    /// Save all entries to disk
    private func save(_ entries: [AutomationLogMessage]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        
        try? data.write(to: fileURL)
    }
}

extension Notification.Name {
    static let automationLogAdded = Notification.Name("automationLogAdded")
    static let automationLogCleared = Notification.Name("automationLogCleared")
}
