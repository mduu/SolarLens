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
        }
    }

    /// Called by `AppDelegate.handle(_:)` for each
    /// `WKWatchConnectivityRefreshBackgroundTask`. We hold the task
    /// and complete it only once `WCSession.hasContentPending` is
    /// `false`.
    func handle(backgroundTask task: WKRefreshBackgroundTask) {
        queue.async { [weak self] in
            guard let self else {
                task.setTaskCompletedWithSnapshot(false)
                return
            }
            self.pendingWCTasks.append(task)
            self.completePendingIfDrained()
        }
    }

    /// Always called on `queue`. Completes every held background task
    /// when WCSession reports no pending content.
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
        publishIfSnapshot(in: session.receivedApplicationContext)
        queue.async { [weak self] in self?.completePendingIfDrained() }
    }

    func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        publishIfSnapshot(in: applicationContext)
        queue.async { [weak self] in self?.completePendingIfDrained() }
    }

    func session(
        _ session: WCSession,
        didReceiveUserInfo userInfo: [String: Any] = [:]
    ) {
        // We don't currently use userInfo for inbound state, but the
        // OS still routes a background task here when the iPhone
        // chose `transferUserInfo`. Drain-check so the task can
        // complete.
        queue.async { [weak self] in self?.completePendingIfDrained() }
    }

    // `sessionReachabilityDidChange` is intentionally NOT implemented.
}
