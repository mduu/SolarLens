internal import Foundation
import WatchConnectivity

/// watchOS-side WatchConnectivity glue for the Automation feature.
///
/// Owns the `WCSessionDelegate` role, performs JSON decode/encode on
/// its own serial queue, and hops to the main actor only when it
/// actually needs to publish a fresh snapshot into
/// `AutomationStateStore.shared`.
///
/// The class is intentionally **not** `@Observable`, **not**
/// `@MainActor`, and exposes no observable state. SwiftUI never reads
/// from it directly. All SwiftUI observation lives in
/// `AutomationStateStore`. This separation isolates Apple's
/// Observation framework from the WatchConnectivity delegate
/// callback queue — a combination that, in this codebase, was
/// reliably the only thing that could make the watch app drift into a
/// frozen state over hours of normal use on real Apple Watch
/// hardware.
final class AutomationWatchSession: NSObject, WCSessionDelegate,
    @unchecked Sendable
{
    static let shared = AutomationWatchSession()

    /// Private serial queue for all WCSession lifecycle operations and
    /// outgoing-command encoding. Inbound delegate methods are
    /// invoked by WCSession on its own queue and dispatch onto this
    /// queue when they need to mutate `didStart`. Everything that
    /// hops to the main actor does so via an explicit
    /// `Task { @MainActor in … }`.
    private let queue = DispatchQueue(
        label: "com.marcduerst.SolarManagerWatch.AutomationWatchSession"
    )

    private var didStart = false

    private override init() { super.init() }

    /// Activate the WCSession. Call once from
    /// `WKApplicationDelegate.applicationDidFinishLaunching`.
    /// Idempotent.
    func start() {
        queue.async { [weak self] in
            guard let self else { return }
            guard !self.didStart else { return }
            guard WCSession.isSupported() else { return }
            self.didStart = true
            WCSession.default.delegate = self
            WCSession.default.activate()
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
    }

    func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        publishIfSnapshot(in: applicationContext)
    }

    // `sessionReachabilityDidChange` is intentionally NOT implemented
    // — see the comment on AutomationStateStore for the rationale.
}
