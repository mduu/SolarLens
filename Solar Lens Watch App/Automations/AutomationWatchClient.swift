internal import Foundation
import WatchConnectivity

/// Master kill-switch for the Automation feature on the watch app.
///
/// When `false`, every newly-introduced code path from the 4.1 watch
/// automation feature is dormant. Kept around so we can flip back to
/// `false` for further isolation if needed.
enum WatchAutomationFeature {
    static let enabled = true
}

/// watchOS-side WatchConnectivity glue for the Automation feature.
///
/// - Receives `AutomationWatchSnapshot` from iOS via
///   `applicationContext` updates (latest-snapshot-wins). Exposes the
///   decoded snapshot as the only `@Observable` property so SwiftUI
///   views re-render automatically.
/// - Sends `AutomationWatchCommand` (start / cancel) back to iOS:
///   `sendMessage` for immediate delivery when the iPhone is reachable,
///   `transferUserInfo` (queued) otherwise.
///
/// The watch UI does NOT block on the reply; it shows optimistic state
/// and converges to the next snapshot push from iOS.
///
/// Deliberately **not** tracking `WCSession.isReachable` — that signal
/// flips constantly on a worn watch (every BT range / sleep / wake
/// edge), and the prior implementation hopped to the main actor +
/// mutated an `@Observable` property on each flip. Over hours of normal
/// use this stress is the prime suspect for the watchOS freeze that
/// landed the app in the system's "do-not-launch" state. We read
/// `session.isReachable` ad-hoc when we actually want to send.
@MainActor
@Observable
final class AutomationWatchClient: NSObject, WCSessionDelegate {

    static let shared = AutomationWatchClient()

    /// Latest snapshot received from iOS, or `nil` if none has arrived
    /// yet (unpaired, app uninstalled on iPhone, or first launch).
    var snapshot: AutomationWatchSnapshot?

    @ObservationIgnored
    private var didStart = false

    @ObservationIgnored
    private var session: WCSession { WCSession.default }

    /// Activate WCSession. Call once from
    /// `WKApplicationDelegate.applicationDidFinishLaunching` so the
    /// delegate is set before iOS delivers any queued payload.
    func start() {
        guard WatchAutomationFeature.enabled else { return }
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
        guard WCSession.isSupported() else { return }
        guard session.activationState == .activated else { return }

        let data: Data
        do {
            data = try JSONEncoder().encode(command)
        } catch {
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
                errorHandler: { [weak self] _ in
                    Task { @MainActor in
                        // Fallback to the queued path so the command
                        // still gets delivered when the phone wakes.
                        self?.session.transferUserInfo(payload)
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
        guard let decoded = try? JSONDecoder().decode(
            AutomationWatchSnapshot.self,
            from: data
        ) else {
            return
        }
        guard decoded.schemaVersion
            == AutomationWatchSnapshot.currentSchemaVersion
        else {
            return
        }
        snapshot = decoded
    }

    // MARK: - WCSessionDelegate

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        let context = session.receivedApplicationContext
        Task { @MainActor in
            self.applyContext(context)
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        Task { @MainActor in self.applyContext(applicationContext) }
    }

    // `sessionReachabilityDidChange` is intentionally NOT implemented.
    // On a worn watch this delegate method fires on every BT range /
    // sleep / wake transition and would otherwise push a main-actor
    // hop + observable mutation per event — accumulating over hours
    // and suspected of triggering watchOS' resource watchdog. We
    // re-read `session.isReachable` directly inside `send()` when we
    // actually need it.
}
