internal import Foundation
import WatchConnectivity

/// iOS-side WatchConnectivity glue for the Automation feature.
///
/// - Pushes an `AutomationWatchSnapshot` to the watch via
///   `updateApplicationContext` whenever `AutomationManager` or relevant
///   `CurrentBuildingState` fields change. Latest-snapshot-wins —
///   coalesced by iOS, no need to throttle aggressively, but we debounce
///   ~500 ms to absorb burst observation re-fires.
/// - Receives `AutomationWatchCommand` from the watch and delegates to
///   `AutomationManager.shared`.
///
/// Activation happens once at app launch from `Solar_Lens_iOSApp.init()`
/// — synchronous so the delegate is set before iOS delivers any queued
/// `transferUserInfo` items.
@MainActor
final class AutomationWatchBridge: NSObject, WCSessionDelegate {

    static let shared = AutomationWatchBridge()

    private var buildingState: CurrentBuildingState?
    private var debounceTask: Task<Void, Never>?
    private var didStart = false

    private var session: WCSession { WCSession.default }

    /// Activate the WCSession and start observing changes. Call once
    /// from `Solar_Lens_iOSApp.init()`. Safe to call multiple times.
    func start(buildingState: CurrentBuildingState) {
        self.buildingState = buildingState
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
    private func observeChanges() {
        withObservationTracking { [weak self] in
            guard let self else { return }
            let mgr = AutomationManager.shared
            _ = mgr.activeAutomation
            _ = mgr.activeStateSnapshot
            _ = mgr.activeParametersSnapshot
            if let overview = self.buildingState?.overviewData {
                _ = overview.hasAnyBattery
                _ = overview.hasAnyCarChargingStation
                _ = overview.chargingStations
                _ = overview.currentBatteryLevel
            }
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
        do {
            let data = try JSONEncoder().encode(snapshot)
            try session.updateApplicationContext(
                [AutomationWCKey.snapshot: data]
            )
        } catch {
            // Logged through AutomationManager so it shows up in the log
            // viewer alongside automation events.
            AutomationManager.shared.logError(
                message: "WatchBridge push failed: \(error)"
            )
        }
    }

    private func makeSnapshot() -> AutomationWatchSnapshot {
        let mgr = AutomationManager.shared
        let overview = buildingState?.overviewData
        return AutomationWatchSnapshot(
            schemaVersion: AutomationWatchSnapshot.currentSchemaVersion,
            lastUpdated: Date(),
            activeAutomation: mgr.activeAutomation,
            state: mgr.activeStateSnapshot,
            parameters: mgr.activeParametersSnapshot,
            prerequisites: .init(
                hasAnyBattery: overview?.hasAnyBattery ?? false,
                hasAnyCarChargingStation:
                    overview?.hasAnyCarChargingStation ?? false
            ),
            chargingStations: overview?.chargingStations.map {
                .init(id: $0.id, name: $0.name)
            } ?? [],
            currentBatteryLevel: overview?.currentBatteryLevel
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
                AutomationManager.shared.startAutomation(
                    automation: automation,
                    parameters: parameters
                )
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
