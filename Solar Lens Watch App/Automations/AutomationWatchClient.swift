internal import Foundation
import WatchConnectivity

/// watchOS-side WatchConnectivity glue for the Automation feature.
///
/// - Receives `AutomationWatchSnapshot` from iOS via
///   `applicationContext` updates (latest-snapshot-wins). Exposes the
///   decoded snapshot as an `@Observable` property so SwiftUI views
///   re-render automatically.
/// - Sends `AutomationWatchCommand` (start / cancel) back to iOS:
///   `sendMessage` for immediate delivery when the iPhone is reachable,
///   `transferUserInfo` (queued) otherwise.
///
/// The watch UI does NOT block on the reply; it shows optimistic state
/// and converges to the next snapshot push from iOS.
@MainActor
@Observable
final class AutomationWatchClient: NSObject, WCSessionDelegate {

    static let shared = AutomationWatchClient()

    /// Latest snapshot received from iOS, or `nil` if none has arrived
    /// yet (unpaired, app uninstalled on iPhone, or first launch).
    var snapshot: AutomationWatchSnapshot?

    /// Whether the iPhone is currently reachable for `sendMessage`. We
    /// fall back to `transferUserInfo` (queued) when this is false.
    var isReachable: Bool = false

    /// Most recent decode / send error, if any. Surfaced for diagnostics
    /// only; the UI relies on the next snapshot push for confirmation.
    var lastError: String?

    @ObservationIgnored
    private var didStart = false

    @ObservationIgnored
    private var session: WCSession { WCSession.default }

    /// Activate WCSession. Call once from
    /// `WKApplicationDelegate.applicationDidFinishLaunching` so the
    /// delegate is set before iOS delivers any queued payload.
    func start() {
        guard !didStart else { return }
        didStart = true
        guard WCSession.isSupported() else { return }
        session.delegate = self
        session.activate()
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
        guard WCSession.isSupported() else {
            lastError = "WatchConnectivity not supported"
            return
        }
        guard session.activationState == .activated else {
            lastError = "WatchConnectivity not activated"
            return
        }

        let data: Data
        do {
            data = try JSONEncoder().encode(command)
        } catch {
            lastError = "encode failed: \(error)"
            return
        }
        let payload: [String: Any] = [AutomationWCKey.command: data]

        if session.isReachable {
            session.sendMessage(
                payload,
                replyHandler: { _ in
                    // Reply is informational only; the snapshot push is
                    // the source of truth.
                },
                errorHandler: { [weak self] error in
                    Task { @MainActor in
                        // Fallback to the queued path so the command
                        // still gets delivered when the phone wakes.
                        self?.session.transferUserInfo(payload)
                        self?.lastError =
                            "sendMessage failed, queued: \(error.localizedDescription)"
                    }
                }
            )
        } else {
            session.transferUserInfo(payload)
        }
    }

    // MARK: - Receiving snapshots

    private func applyContext(_ context: [String: Any]) {
        guard let data = context[AutomationWCKey.snapshot] as? Data else {
            return
        }
        do {
            let decoded = try JSONDecoder().decode(
                AutomationWatchSnapshot.self,
                from: data
            )
            guard decoded.schemaVersion
                == AutomationWatchSnapshot.currentSchemaVersion
            else {
                lastError =
                    "snapshot schema mismatch: got \(decoded.schemaVersion)"
                return
            }
            snapshot = decoded
            lastError = nil
        } catch {
            lastError = "decode failed: \(error)"
        }
    }

    // MARK: - WCSessionDelegate

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        let context = session.receivedApplicationContext
        let reachable = session.isReachable
        Task { @MainActor in
            self.isReachable = reachable
            self.applyContext(context)
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        Task { @MainActor in self.applyContext(applicationContext) }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let reachable = session.isReachable
        Task { @MainActor in self.isReachable = reachable }
    }
}
