import Foundation

final class ScenarioLogManager {
    static let shared = ScenarioLogManager()

    private let fileURL: URL = {
        let dir = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
        return dir.appendingPathComponent("scenario-logs.json")
    }()

    // Append a new entry
    func log(
        _ message: ScenarioLogMessage
    ) {
        var logs = load()
        logs.append(message)
        save(logs)
        NotificationCenter.default
            .post(name: .scenarioLogAdded, object: logs.last)
    }
    
    /// Load all entries from disk
    func load() -> [ScenarioLogMessage] {
        guard let data = try? Data(contentsOf: fileURL),
            let entries = try? JSONDecoder().decode(
                [ScenarioLogMessage].self,
                from: data
            )
        else { return [] }
        
        return entries
    }
    
    func clearAll() -> Void {
        save([])
        NotificationCenter.default
            .post(name: .scenarioLogCleared, object: nil)

    }

    /// Save all entries to disk
    private func save(_ entries: [ScenarioLogMessage]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        
        try? data.write(to: fileURL)
    }
}

extension Notification.Name {
    static let scenarioLogAdded = Notification.Name("scenarioLogAdded")
    static let scenarioLogCleared = Notification.Name("scenarioLogCleared")
}
