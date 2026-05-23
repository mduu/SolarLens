internal import Foundation
internal import OSLog

/// On-device diagnostics for the watchOS app, motivated by the
/// reproducible-but-undiagnosable freeze on real Apple Watch hardware.
///
/// watchOS does not have MetricKit (iOS/macOS only), and Console.app /
/// Xcode Organizer reliably show no useful data for this app, so this
/// collector is the only channel we have.
///
/// What it captures:
///
/// 1. **Lifecycle breadcrumbs** — launch, scenePhase transitions,
///    WCSession activations / errors, BG-task scheduling — written
///    explicitly from the relevant call sites.
///
/// 2. **Heartbeat** — every 60 s while the scene is `.active`, a
///    `heartbeat` entry is appended with current memory footprint. The
///    last heartbeat before a freeze tells us the state right before
///    the OS stopped scheduling us; a long gap followed by a fresh
///    `launch` after a force-quit pins the freeze duration.
///
/// All entries land in a rolling JSON-lines file (max 256 KB) in
/// Documents and are surfaced in-app via `DiagnosticsView` (Settings →
/// Diagnostics).
///
/// Thread safety: file I/O is serialized through `queue`. Heartbeat
/// timer is created on the main actor in `start()`.
@MainActor
final class WatchDiagnostics {

    static let shared = WatchDiagnostics()

    private static let logger = Logger(
        subsystem: "com.marcduerst.SolarManagerWatch",
        category: "Diagnostics"
    )

    nonisolated static let logFileName = "watch-diagnostics.log"

    /// Roll the file at this size. 256 KB is generous for JSON-lines
    /// breadcrumbs and survives many days of heartbeats.
    private let maxLogSize = 256 * 1024

    /// Cadence at which the foreground heartbeat fires. 60 s is a
    /// pragmatic compromise: granular enough to pin a freeze-induced
    /// gap to within a minute, sparse enough to not feed back into the
    /// resource-budget pressure we're trying to diagnose.
    private let heartbeatInterval: TimeInterval = 60

    private let queue = DispatchQueue(
        label: "com.marcduerst.SolarManagerWatch.WatchDiagnostics"
    )

    private var heartbeatTimer: Timer?

    private init() {}

    /// Call from `AppDelegate.applicationDidFinishLaunching`.
    func start() {
        appendBreadcrumb(
            kind: "launch",
            data: [
                "watchOSVersion":
                    ProcessInfo.processInfo.operatingSystemVersionString,
                "appVersion":
                    Bundle.main.infoDictionary?["CFBundleShortVersionString"]
                    as? String ?? "?",
                "build":
                    Bundle.main.infoDictionary?["CFBundleVersion"]
                    as? String ?? "?",
            ]
        )
        Self.logger.notice(
            "WatchDiagnostics started — log at \(self.logFileURL?.path ?? "n/a", privacy: .public)"
        )
    }

    /// Called from the scenePhase observer in
    /// `SolarManagerWatch_Watch_AppApp`. Keeps the heartbeat alive only
    /// while the scene is active — when we drop to inactive/background
    /// the OS isn't going to schedule us anyway, so heartbeats would
    /// just be noise.
    func scenePhaseChanged(toActive isActive: Bool) {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        guard isActive else { return }
        let t = Timer(timeInterval: heartbeatInterval, repeats: true) {
            [weak self] _ in
            self?.appendBreadcrumb(kind: "heartbeat")
        }
        RunLoop.main.add(t, forMode: .common)
        heartbeatTimer = t
        // Fire one immediately so we have a marker at the transition.
        appendBreadcrumb(kind: "heartbeat-initial")
    }

    /// Append a single lifecycle marker. Cheap; safe to call from any
    /// thread. Use sparingly — at meaningful state transitions only.
    nonisolated func appendBreadcrumb(
        kind: String,
        data: [String: Any] = [:]
    ) {
        var merged = data
        if merged["memoryFootprintBytes"] == nil {
            merged["memoryFootprintBytes"] =
                Self.currentMemoryFootprint() as Any
        }
        let entry: [String: Any] = [
            "ts": Date().timeIntervalSince1970,
            "kind": kind,
            "data": merged,
        ]
        write(entry: entry)
    }

    // MARK: - File access

    nonisolated var logFileURL: URL? {
        guard
            let docs = FileManager.default.urls(
                for: .documentDirectory, in: .userDomainMask
            ).first
        else { return nil }
        return docs.appendingPathComponent(Self.logFileName)
    }

    nonisolated func readAll() -> String {
        guard let url = logFileURL,
            let data = try? Data(contentsOf: url),
            let str = String(data: data, encoding: .utf8)
        else { return "" }
        return str
    }

    nonisolated func clear() {
        queue.async { [weak self] in
            guard let self, let url = self.logFileURL else { return }
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - Internal

    nonisolated private func write(entry: [String: Any]) {
        queue.async { [weak self] in
            guard let self, let url = self.logFileURL else { return }
            guard let line = Self.encodeLine(entry) else { return }
            Self.appendData(line, to: url)
            self.trimIfNeeded(at: url)
        }
    }

    nonisolated private static func encodeLine(
        _ entry: [String: Any]
    ) -> Data? {
        guard JSONSerialization.isValidJSONObject(entry) else { return nil }
        guard
            let data = try? JSONSerialization.data(
                withJSONObject: entry,
                options: [.sortedKeys]
            )
        else { return nil }
        return data + Data([0x0A])  // newline
    }

    nonisolated private static func appendData(_ data: Data, to url: URL) {
        let fm = FileManager.default
        if !fm.fileExists(atPath: url.path) {
            fm.createFile(atPath: url.path, contents: data)
            return
        }
        if let handle = try? FileHandle(forWritingTo: url) {
            defer { try? handle.close() }
            _ = try? handle.seekToEnd()
            try? handle.write(contentsOf: data)
        }
    }

    nonisolated private func trimIfNeeded(at url: URL) {
        let fm = FileManager.default
        guard let attrs = try? fm.attributesOfItem(atPath: url.path),
            let size = attrs[.size] as? Int,
            size > maxLogSize
        else { return }
        guard let data = try? Data(contentsOf: url) else { return }
        // Keep the last `maxLogSize` bytes, dropping the partial leading
        // line so the file remains valid JSON-lines.
        let tail = data.suffix(maxLogSize)
        if let firstNewlineIdx = tail.firstIndex(of: 0x0A) {
            let kept = tail[(firstNewlineIdx + 1)...]
            try? Data(kept).write(to: url, options: .atomic)
        }
    }

    nonisolated private static func currentMemoryFootprint() -> UInt64? {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<task_vm_info_data_t>.size
                / MemoryLayout<integer_t>.size
        )
        let kr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(TASK_VM_INFO),
                    $0,
                    &count
                )
            }
        }
        return kr == KERN_SUCCESS ? info.phys_footprint : nil
    }
}
