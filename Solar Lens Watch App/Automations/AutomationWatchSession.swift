internal import Foundation
import WatchConnectivity
import WatchKit

/// watchOS-side WatchConnectivity glue for the Automation feature.
///
/// Owns the `WCSessionDelegate` role, performs JSON decode/encode on
/// its own serial queue, and hops to the main actor only when it
/// actually needs to publish a fresh snapshot into
/// `AutomationStateStore.shared`.
///
/// **Background-task contract.** When iOS delivers an
/// `applicationContext` while the watch app is suspended, watchOS
/// wakes us via a `WKWatchConnectivityRefreshBackgroundTask`. We are
/// required to keep that task alive until `WCSession.hasContentPending`
/// is `false`, then call `setTaskCompletedWithSnapshot(false)`. If we
/// don't, watchOS treats us as misbehaving — and over a day's worth of
/// nightly deliveries that's the resource accounting violation that
/// eventually pins our app onto watchOS's do-not-launch list (the
/// exact freeze symptom users reported in 4.1).
///
/// The class is intentionally **not** `@Observable`, **not**
/// `@MainActor`, and exposes no observable state. SwiftUI never reads
/// from it directly; all SwiftUI observation lives in
/// `AutomationStateStore`.
final class AutomationWatchSession: NSObject, WCSessionDelegate,
    @unchecked Sendable
{
    static let shared = AutomationWatchSession()

    /// Private serial queue for all WCSession lifecycle operations,
    /// outgoing-command encoding, and the pending background-task
    /// list.
    private let queue = DispatchQueue(
        label: "com.marcduerst.SolarManagerWatch.AutomationWatchSession"
    )

    private var didActivate = false

    /// Background tasks the system handed us to acknowledge once the
    /// `WCSession` has drained all pending content. Apple's contract:
    /// keep these alive until `hasContentPending == false`.
    private var pendingWCTasks: [WKRefreshBackgroundTask] = []

    private override init() { super.init() }

    /// Activate the WCSession and attach as delegate. Call once from
    /// `WKApplicationDelegate.applicationDidFinishLaunching` — per
    /// Apple's guidance the session stays activated for the full
    /// process lifetime. Idempotent.
    func start() {
        queue.async { [weak self] in
            guard let self else { return }
            guard !self.didActivate else { return }
            guard WCSession.isSupported() else { return }
            self.didActivate = true
            WCSession.default.delegate = self
            WCSession.default.activate()
            WatchDiagnostics.shared.appendBreadcrumb(kind: "wc-start")
        }
    }

    /// Hard ceiling on how long we'll hold a
    /// `WKWatchConnectivityRefreshBackgroundTask` before force-
    /// completing it. watchOS grants roughly 30 s of background
    /// runtime per refresh task; sitting on one until the OS reclaims
    /// the runtime counts as misbehavior. 25 s gives us safety
    /// margin.
    private static let backgroundTaskTimeout: TimeInterval = 25

    /// Called by `AppDelegate.handle(_:)` for each
    /// `WKWatchConnectivityRefreshBackgroundTask`. We complete the
    /// task immediately if WCSession reports nothing pending (a
    /// common case when the OS opportunistically wakes us without
    /// new content); otherwise we hold it under an explicit timeout
    /// so a stalled framework state can never make us miss the
    /// deadline.
    func handle(backgroundTask task: WKRefreshBackgroundTask) {
        queue.async { [weak self] in
            guard let self else {
                task.setTaskCompletedWithSnapshot(false)
                return
            }
            let session = WCSession.default

            // Race-safe early exit: if the session isn't fully
            // activated yet at this exact moment, we have no clean
            // way to know whether content is coming. Complete the
            // task now — the framework will still deliver any
            // subsequent applicationContext via the regular
            // delegate path; we don't lose data.
            if session.activationState != .activated {
                task.setTaskCompletedWithSnapshot(false)
                return
            }

            // Fast path: framework reports the queue is already
            // drained. No need to hold the task at all.
            if !session.hasContentPending {
                task.setTaskCompletedWithSnapshot(false)
                return
            }

            // Slow path: park the task and arm a hard timeout.
            self.pendingWCTasks.append(task)
            self.queue.asyncAfter(
                deadline: .now() + Self.backgroundTaskTimeout
            ) { [weak self] in
                guard let self else { return }
                if let idx = self.pendingWCTasks.firstIndex(
                    where: { $0 === task }
                ) {
                    self.pendingWCTasks.remove(at: idx)
                    task.setTaskCompletedWithSnapshot(false)
                }
            }
        }
    }

    /// Always called on `queue`. Completes every held background task
    /// when WCSession reports no pending content. Safe to call
    /// repeatedly; once a task has been completed (here or by the
    /// timeout) it is removed from the pending list.
    private func completePendingIfDrained() {
        let session = WCSession.default
        guard session.activationState == .activated,
              !session.hasContentPending
        else { return }
        let tasks = pendingWCTasks
        pendingWCTasks.removeAll()
        for task in tasks {
            task.setTaskCompletedWithSnapshot(false)
        }
    }

    // MARK: - Diagnostics export

    /// Ships the current `watch-diagnostics.log` to the iPhone via
    /// `WCSession.transferFile`. iOS persists it and surfaces it under
    /// Settings → Activity log. Best-effort: silently no-ops if the
    /// session isn't activated or the log doesn't exist yet.
    ///
    /// We snapshot the live log into a temp file before transferring
    /// so a concurrent write from the diagnostics queue can't corrupt
    /// the bytes WatchConnectivity is reading.
    func exportLogToPhone() {
        queue.async { [weak self] in
            guard let self else { return }
            guard WCSession.isSupported() else { return }
            let session = WCSession.default
            guard session.activationState == .activated else { return }
            guard let src = WatchDiagnostics.shared.logFileURL,
                FileManager.default.fileExists(atPath: src.path)
            else {
                WatchDiagnostics.shared.appendBreadcrumb(
                    kind: "wc-export-skipped",
                    data: ["reason": "no log file"]
                )
                return
            }
            // Snapshot into a temp file. Name carries timestamp so the
            // iPhone-side filename is informative.
            let ts = Int(Date().timeIntervalSince1970)
            let tempDir = FileManager.default.temporaryDirectory
            let dest = tempDir.appendingPathComponent(
                "watch-diagnostics-\(ts).log"
            )
            do {
                if FileManager.default.fileExists(atPath: dest.path) {
                    try FileManager.default.removeItem(at: dest)
                }
                try FileManager.default.copyItem(at: src, to: dest)
            } catch {
                WatchDiagnostics.shared.appendBreadcrumb(
                    kind: "wc-export-failed",
                    data: ["stage": "copy", "error": error.localizedDescription]
                )
                return
            }
            session.transferFile(
                dest,
                metadata: ["kind": "diagnostics-log"]
            )
            WatchDiagnostics.shared.appendBreadcrumb(
                kind: "wc-export-started"
            )
        }
    }

    func session(
        _ session: WCSession,
        didFinish fileTransfer: WCSessionFileTransfer,
        error: (any Error)?
    ) {
        // Clean up the temp snapshot regardless of success.
        try? FileManager.default.removeItem(at: fileTransfer.file.fileURL)
        WatchDiagnostics.shared.appendBreadcrumb(
            kind: "wc-export-done",
            data: [
                "ok": error == nil,
                "error": error?.localizedDescription ?? "",
            ]
        )
    }

    // MARK: - Sending commands

    func startAutomation(
        _ automation: Automation,
        parameters: AutomationParameters
    ) {
        send(.start(automation: automation, parameters: parameters))
    }

    func cancelActiveAutomation() {
        send(.cancel)
    }

    private func send(_ command: AutomationWatchCommand) {
        queue.async {
            guard WCSession.isSupported() else { return }
            let session = WCSession.default
            guard session.activationState == .activated else { return }

            guard let data = try? JSONEncoder().encode(command) else {
                return
            }
            let payload: [String: Any] = [AutomationWCKey.command: data]

            if session.isReachable {
                session.sendMessage(
                    payload,
                    replyHandler: { _ in
                        // Reply is informational only; the snapshot
                        // push is the source of truth.
                    },
                    errorHandler: { _ in
                        // Fall back to the queued path so the command
                        // still gets delivered when the phone wakes.
                        WCSession.default.transferUserInfo(payload)
                    }
                )
            } else {
                session.transferUserInfo(payload)
            }
        }
    }

    // MARK: - Snapshot publishing

    /// Decode the snapshot payload (if any) and publish it to
    /// `AutomationStateStore.shared`. Runs entirely off the main
    /// actor; the single MainActor hop is the final assignment.
    private func publishIfSnapshot(in payload: [String: Any]) {
        guard let data = payload[AutomationWCKey.snapshot] as? Data,
              let decoded = try? JSONDecoder().decode(
                AutomationWatchSnapshot.self, from: data
              ),
              decoded.schemaVersion
                == AutomationWatchSnapshot.currentSchemaVersion
        else { return }

        Task { @MainActor in
            AutomationStateStore.shared.snapshot = decoded
        }
    }

    // MARK: - WCSessionDelegate

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        WatchDiagnostics.shared.appendBreadcrumb(
            kind: "wc-activated",
            data: [
                "state": activationState.rawValue,
                "error": error?.localizedDescription ?? "",
            ]
        )
        publishIfSnapshot(in: session.receivedApplicationContext)
        queue.async { [weak self] in self?.completePendingIfDrained() }
    }

    func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        WatchDiagnostics.shared.appendBreadcrumb(kind: "wc-appcontext")
        publishIfSnapshot(in: applicationContext)
        queue.async { [weak self] in self?.completePendingIfDrained() }
    }

    func session(
        _ session: WCSession,
        didReceiveUserInfo userInfo: [String: Any] = [:]
    ) {
        WatchDiagnostics.shared.appendBreadcrumb(kind: "wc-userinfo")
        // We don't currently use userInfo for inbound state, but the
        // OS still routes a background task here when the iPhone
        // chose `transferUserInfo`. Drain-check so the task can
        // complete.
        queue.async { [weak self] in self?.completePendingIfDrained() }
    }

    // `sessionReachabilityDidChange` is intentionally NOT implemented.
}
