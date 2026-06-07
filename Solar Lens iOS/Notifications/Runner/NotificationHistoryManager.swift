internal import Foundation
import Observation

/// One delivered (= locally pushed) notification, kept so the user can
/// review *when which* notification fired from the Notifications tab.
struct NotificationFiredEvent: Codable, Identifiable {
    let id: UUID
    let kind: SolarLensNotification
    /// Measured value at fire time (percent or watts, per kind).
    let value: Int
    /// Configured threshold (percent or watts, per kind).
    let threshold: Int
    let comparison: NotificationComparison
    let time: Date
}

/// Persists the fired-notification history. Mirrors
/// `AutomationLogManager`'s simple JSON-file approach — small,
/// append-mostly data read only when the history sheet is opened.
///
/// `@Observable` so the unread count can drive badges (tab bar, history
/// toolbar button) reactively. Unread = fired after `lastReadAt`, which
/// is bumped to "now" whenever the history sheet is opened.
@Observable
@MainActor
final class NotificationHistoryManager {
    static let shared = NotificationHistoryManager()

    /// Number of events fired since the user last opened the history.
    private(set) var unreadCount: Int = 0

    /// Hard cap so the file can't grow unbounded.
    private static let maxEntries = 500

    private static let lastReadKey =
        "SolarLens.notifications.historyLastReadAt"

    @ObservationIgnored
    private let fileURL: URL = {
        let dir = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
        return dir.appendingPathComponent("notification-history.json")
    }()

    private init() {
        refreshUnreadCount()
    }

    private var lastReadAt: Date {
        get {
            UserDefaults.standard
                .object(forKey: Self.lastReadKey) as? Date ?? .distantPast
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.lastReadKey)
        }
    }

    /// Append a new fired event.
    func record(_ event: NotificationFiredEvent) {
        var events = load()
        events.append(event)
        if events.count > Self.maxEntries {
            events.removeFirst(events.count - Self.maxEntries)
        }
        save(events)
        refreshUnreadCount()
        NotificationCenter.default
            .post(name: .notificationHistoryAdded, object: event)
    }

    /// Load all events from disk.
    func load() -> [NotificationFiredEvent] {
        guard let data = try? Data(contentsOf: fileURL),
            let events = try? JSONDecoder().decode(
                [NotificationFiredEvent].self,
                from: data
            )
        else { return [] }

        return events
    }

    /// Marks every event as read (called when the history sheet opens).
    func markAllRead() {
        lastReadAt = Date()
        unreadCount = 0
    }

    func clearAll() {
        save([])
        unreadCount = 0
        NotificationCenter.default
            .post(name: .notificationHistoryCleared, object: nil)
    }

    private func refreshUnreadCount() {
        let readMark = lastReadAt
        unreadCount = load().filter { $0.time > readMark }.count
    }

    private func save(_ events: [NotificationFiredEvent]) {
        guard let data = try? JSONEncoder().encode(events) else { return }

        try? data.write(to: fileURL)
    }
}

extension Notification.Name {
    static let notificationHistoryAdded =
        Notification.Name("notificationHistoryAdded")
    static let notificationHistoryCleared =
        Notification.Name("notificationHistoryCleared")
}
