internal import Foundation

/// Persistent storage for activity logs shipped from the watch via
/// WatchConnectivity. The receive path runs in `AutomationWatchBridge`
/// (any thread, called by the OS), so the API is `nonisolated` and
/// uses serial file operations.
///
/// Files are kept in `Documents/WatchLogs/`, named with the original
/// timestamp the watch baked into the filename (e.g.
/// `watch-diagnostics-1747890123.log`). That keeps the list naturally
/// sortable by ingest time without needing an index file.
final class WatchLogsStore: @unchecked Sendable {

    static let shared = WatchLogsStore()

    private init() {}

    /// Directory where ingested watch logs live. Created lazily.
    var directoryURL: URL? {
        guard
            let docs = FileManager.default.urls(
                for: .documentDirectory, in: .userDomainMask
            ).first
        else { return nil }
        let dir = docs.appendingPathComponent(
            "WatchLogs", isDirectory: true
        )
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(
                at: dir,
                withIntermediateDirectories: true
            )
        }
        return dir
    }

    /// Move (or copy-then-delete) a temp file the OS handed us in
    /// `session(_:didReceive:)` into permanent storage. Returns the
    /// destination URL.
    func ingest(temporaryFile src: URL) throws -> URL {
        guard let dir = directoryURL else {
            throw NSError(
                domain: "WatchLogsStore", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "no documents dir"]
            )
        }
        // Preserve the watch-chosen filename (carries the unix timestamp).
        let dest = dir.appendingPathComponent(src.lastPathComponent)
        if FileManager.default.fileExists(atPath: dest.path) {
            try FileManager.default.removeItem(at: dest)
        }
        // copy, not move: WatchConnectivity owns the source and may
        // delete or refuse-to-move; copy is the documented safe route.
        try FileManager.default.copyItem(at: src, to: dest)
        return dest
    }

    /// All ingested log files, newest first.
    func allFiles() -> [URL] {
        guard let dir = directoryURL else { return [] }
        let urls =
            (try? FileManager.default.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )) ?? []
        return urls.sorted { a, b in
            modificationDate(of: a) > modificationDate(of: b)
        }
    }

    func delete(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    func deleteAll() {
        for url in allFiles() {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private func modificationDate(of url: URL) -> Date {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey])
            .contentModificationDate) ?? .distantPast
    }
}
