internal import Foundation
import UIKit
import WatchConnectivity

/// iOS-side WatchConnectivity glue for the Automation feature.
///
/// - Pushes an `AutomationWatchSnapshot` to the watch via
///   `updateApplicationContext` whenever `AutomationManager`'s active
///   automation state actually changes (not just timestamps).
/// - Receives `AutomationWatchCommand` from the watch and delegates to
///   `AutomationManager.shared`.
///
/// The snapshot deliberately only carries iPhone-exclusive automation
/// state — the watch already loads Solar Manager telemetry (charging
/// stations, battery level, prerequisites) on its own via REST, so we
/// don't duplicate it here. That keeps the push frequency at "only
/// when an automation actually changes" — typically a single push at
/// app launch, then zero pushes when idle, and one per tick (~60 s)
/// while a run is active.
///
/// Activation happens once at app launch from `Solar_Lens_iOSApp.init()`
/// — synchronous so the delegate is set before iOS delivers any queued
/// `transferUserInfo` items.
@MainActor
final class AutomationWatchBridge: NSObject, WCSessionDelegate {

    static let shared = AutomationWatchBridge()

    private var debounceTask: Task<Void, Never>?
    private var didStart = false

    /// Last payload actually sent to the watch. Used to skip
    /// `updateApplicationContext` when the snapshot is bit-identical
    /// to the previous push — otherwise iOS will happily ship the
    /// same payload over and over and the watch will re-decode +
    /// re-render for no reason.
    private var lastPushedData: Data?

    private var session: WCSession { WCSession.default }

    /// Activate the WCSession and start observing changes. Call once
    /// from `Solar_Lens_iOSApp.init()`. Safe to call multiple times.
    func start() {
        guard !didStart else { return }
        didStart = true

        guard WCSession.isSupported() else { return }
        session.delegate = self
        session.activate()

        NotificationCenter.default.addObserver(
            forName: AutomationManager.automationTerminatedNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.scheduleSnapshotPush() }
        }

        observeChanges()
    }

    // MARK: - Observation loop

    /// Re-arms `withObservationTracking` after each fire.
    /// `withObservationTracking` is one-shot; we re-subscribe inside
    /// `onChange` to keep listening for the next change.
    ///
    /// Tracks **only** `AutomationManager.shared`'s state. The watch
    /// reads its own Solar Manager data for everything else, so we
    /// deliberately do NOT track `CurrentBuildingState` here — that
    /// would push the watch every 15 s for nothing.
    private func observeChanges() {
        withObservationTracking { [weak self] in
            guard let self else { return }
            let mgr = AutomationManager.shared
            _ = mgr.activeAutomation
            _ = mgr.activeStateSnapshot
            _ = mgr.activeParametersSnapshot
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.scheduleSnapshotPush()
                self?.observeChanges()
            }
        }
    }

    private func scheduleSnapshotPush() {
        debounceTask?.cancel()
        debounceTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            self.pushSnapshot()
        }
    }

    private func pushSnapshot() {
        guard WCSession.isSupported() else { return }
        guard session.activationState == .activated else { return }
        let snapshot = makeSnapshot()
        let data: Data
        do {
            data = try JSONEncoder().encode(snapshot)
        } catch {
            AutomationManager.shared.logError(
                message: "WatchBridge encode failed: \(error)"
            )
            return
        }
        if data == lastPushedData {
            // Content unchanged since the last push — skip the
            // WCSession roundtrip and the watch-side re-render it
            // would cause.
            return
        }
        do {
            try session.updateApplicationContext(
                [AutomationWCKey.snapshot: data]
            )
            lastPushedData = data
        } catch {
            AutomationManager.shared.logError(
                message: "WatchBridge push failed: \(error)"
            )
        }
    }

    private func makeSnapshot() -> AutomationWatchSnapshot {
        let mgr = AutomationManager.shared
        return AutomationWatchSnapshot(
            schemaVersion: AutomationWatchSnapshot.currentSchemaVersion,
            activeAutomation: mgr.activeAutomation,
            state: mgr.activeStateSnapshot,
            parameters: mgr.activeParametersSnapshot
        )
    }

    // MARK: - WCSessionDelegate

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in self.pushSnapshot() }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Reactivate to keep receiving messages from a freshly-paired
        // watch (e.g. user paired a different watch).
        WCSession.default.activate()
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        Task { @MainActor in
            let result = self.handleCommand(payload: message)
            replyHandler(result)
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveUserInfo userInfo: [String: Any] = [:]
    ) {
        Task { @MainActor in
            _ = self.handleCommand(payload: userInfo)
        }
    }

    /// Receives the rolling activity log shipped from the watch via
    /// `DiagnosticsView`. We copy the temp file out of the
    /// WatchConnectivity-controlled location immediately (the OS
    /// reclaims it shortly after this callback returns) into the iOS
    /// app Documents dir, where Settings → Activity log can list and
    /// share it.
    nonisolated func session(
        _ session: WCSession,
        didReceive file: WCSessionFile
    ) {
        let metadata = file.metadata ?? [:]
        guard metadata["kind"] as? String == "diagnostics-log" else { return }
        let src = file.fileURL
        do {
            let dest = try WatchLogsStore.shared
                .ingest(temporaryFile: src)
            print("WatchBridge: received diagnostics log → \(dest.path)")
        } catch {
            print("WatchBridge: failed to ingest diagnostics log: \(error)")
        }
    }

    @MainActor
    private func handleCommand(payload: [String: Any]) -> [String: Any] {
        guard let data = payload[AutomationWCKey.command] as? Data else {
            return ["ok": false, "error": "missing command data"]
        }
        do {
            let cmd = try JSONDecoder().decode(
                AutomationWatchCommand.self,
                from: data
            )
            switch cmd {
            case .start(let automation, let parameters):
                // ActivityKit's `Activity.request(...)` for an in-app
                // (non-push) Live Activity needs the app to be either
                // foreground or holding an explicit background-runtime
                // claim. WCSession message delivery alone gives us only
                // a brief processing window; once it lapses the LA
                // request silently gets deferred to the next `update()`
                // — which is exactly the "appears minutes later" symptom
                // users see when starting from the watch.
                //
                // Open a UIBackgroundTask so iOS keeps us alive long
                // enough for AutomationLiveActivityCoordinator's async
                // request-activity Task to complete. 8 s is comfortably
                // longer than the typical `endStaleActivities` + request
                // round-trip and well within the OS budget.
                let app = UIApplication.shared
                var bgTask: UIBackgroundTaskIdentifier = .invalid
                bgTask = app.beginBackgroundTask(
                    withName: "AutomationStartFromWatch"
                ) {
                    if bgTask != .invalid {
                        app.endBackgroundTask(bgTask)
                        bgTask = .invalid
                    }
                }

                AutomationManager.shared.startAutomation(
                    automation: automation,
                    parameters: parameters
                )

                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(8))
                    if bgTask != .invalid {
                        app.endBackgroundTask(bgTask)
                        bgTask = .invalid
                    }
                }
            case .cancel:
                AutomationManager.shared.cancelActiveAutomation()
            }
            // Push back fresh state immediately so the watch reflects
            // the result without waiting for the debounce window.
            scheduleSnapshotPush()
            return ["ok": true]
        } catch {
            return ["ok": false, "error": String(describing: error)]
        }
    }
}
