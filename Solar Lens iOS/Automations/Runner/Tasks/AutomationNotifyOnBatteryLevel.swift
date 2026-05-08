internal import Foundation

/// Automation: poll the house battery every few minutes and fire a local
/// notification once the level meets a user-chosen condition (≥ X% or
/// ≤ X%). The automation does not control any wallbox — its only effect
/// on the world is the notification at the end of a successful run.
///
/// Self-cancels if no match is found within 24 h, so a poorly-chosen
/// threshold can't run forever in the background.
final class AutomationNotifyOnBatteryLevel: AutomationTask {
    public static let shared = AutomationNotifyOnBatteryLevel()

    let automationName: LocalizedStringResource = "Notify on battery level"

    /// Polling cadence. Story #6 spec: "every about 5–10 minutes". 5 min
    /// is the responsiveness/battery-budget sweet spot; iOS BG often
    /// fires a refresh in that window, and 5 min × 24 h = 288 ticks at
    /// most before the timeout kicks in.
    private let monitorInterval: TimeInterval = 5 * 60

    /// Maximum total run duration before we auto-cancel. Acts as a
    /// safety net for thresholds that won't realistically be reached
    /// (e.g. user picks "≥ 95 %" on a sunny morning the next day will
    /// be cloudy).
    private let maxRunDuration: TimeInterval = 24 * 60 * 60

    func run(
        host: any AutomationHost,
        parameters: AutomationParameters,
        state: AutomationState
    ) async throws -> AutomationState {
        guard let params = parameters.notifyOnBatteryLevel,
              let liveState0 = state.notifyOnBatteryLevel else {
            host.logError(
                message: "Notify on battery level: missing parameters"
            )
            host.logFailure()
            return state.failed()
        }

        // First tick: capture the start time and snapshot whatever
        // battery level is already visible.
        if !liveState0.isStarted {
            return await startRun(
                host: host,
                parameters: params,
                state: state
            )
        }

        // Auto-cancel after 24 h. Honest stop reason so the user gets a
        // helpful "still no match" notification rather than going silent.
        if let startedAt = liveState0.startedAt,
           Date().timeIntervalSince(startedAt) >= maxRunDuration {
            return await timeoutRun(
                host: host,
                parameters: params,
                state: state,
                liveState: liveState0
            )
        }

        // Fetch the current battery level. Failures are non-terminal —
        // we just keep waiting; the `runActiveAutomation` retry loop
        // already absorbs three consecutive errors before giving up.
        guard let batteryLevel = await fetchBatteryLevel(host: host) else {
            return scheduleNextTick(
                state: liveState0, in: state
            )
        }

        var live = liveState0
        live.lastBatteryLevel = batteryLevel
        live.lastTickAt = Date()

        if Self.conditionMet(level: batteryLevel, params: params) {
            return await finishRun(
                host: host,
                parameters: params,
                state: state,
                liveState: live
            )
        }

        host.logDebug(
            message:
                "Notify on battery level: \(batteryLevel)% — \(describe(params)), waiting"
        )
        return scheduleNextTick(state: live, in: state)
    }

    // MARK: - Telemetry

    private func fetchBatteryLevel(
        host: any AutomationHost
    ) async -> Int? {
        let overview: OverviewData
        do {
            overview = try await host.energyManager
                .fetchOverviewData(lastOverviewData: nil)
        } catch {
            host.logError(
                message:
                    "Notify on battery level: fetch overview failed (\(error.localizedDescription)); will retry next tick"
            )
            return nil
        }
        guard let soc = overview.currentBatteryLevel else {
            host.logError(
                message:
                    "Notify on battery level: no battery level reading from house battery; cannot tick"
            )
            return nil
        }
        return soc
    }

    /// Pure: did the observed level satisfy the user-chosen condition?
    static func conditionMet(
        level: Int,
        params: AutomationNotifyOnBatteryLevelParameters
    ) -> Bool {
        switch params.comparison {
        case .equalOrAbove: return level >= params.targetBatteryLevel
        case .equalOrBelow: return level <= params.targetBatteryLevel
        }
    }

    // MARK: - Start

    private func startRun(
        host: any AutomationHost,
        parameters params: AutomationNotifyOnBatteryLevelParameters,
        state: AutomationState
    ) async -> AutomationState {
        host.logDebug(message: "Notify on battery level: starting")
        let level = await fetchBatteryLevel(host: host)

        host.logInfo(
            message:
                "Notify on battery level: started — target \(describe(params))"
        )

        var live = AutomationNotifyOnBatteryLevelState()
        live.isStarted = true
        live.startedAt = Date()
        live.lastTickAt = Date()
        live.lastBatteryLevel = level

        // If the condition is already met on first tick, finish
        // immediately. Slightly counter-intuitive UX (start, get
        // notification right away) but the alternative — silently
        // ignoring the very first reading — is worse.
        if let level, Self.conditionMet(level: level, params: params) {
            return await finishRun(
                host: host,
                parameters: params,
                state: state,
                liveState: live
            )
        }

        return AutomationState(
            automation: state.automation!,
            status: .running,
            nextTaskRun: Date().addingTimeInterval(monitorInterval),
            notifyOnBatteryLevel: live
        )
    }

    // MARK: - Finish (condition met)

    private func finishRun(
        host: any AutomationHost,
        parameters params: AutomationNotifyOnBatteryLevelParameters,
        state: AutomationState,
        liveState: AutomationNotifyOnBatteryLevelState
    ) async -> AutomationState {
        var stopped = liveState
        stopped.stopReason = .conditionMet
        host.logInfo(
            message:
                "Notify on battery level: condition met — battery \(liveState.lastBatteryLevel ?? 0)%, target \(describe(params))"
        )
        host.logSuccess()
        return AutomationState(
            automation: state.automation!,
            status: .finishedSuccessful,
            nextTaskRun: nil,
            notifyOnBatteryLevel: stopped
        )
    }

    // MARK: - Timeout (24h auto-cancel)

    private func timeoutRun(
        host: any AutomationHost,
        parameters params: AutomationNotifyOnBatteryLevelParameters,
        state: AutomationState,
        liveState: AutomationNotifyOnBatteryLevelState
    ) async -> AutomationState {
        var stopped = liveState
        stopped.stopReason = .timedOut
        host.logInfo(
            message:
                "Notify on battery level: 24 h timeout — last battery \(liveState.lastBatteryLevel ?? 0)%, target \(describe(params))"
        )
        host.logSuccess()
        return AutomationState(
            automation: state.automation!,
            status: .finishedSuccessful,
            nextTaskRun: nil,
            notifyOnBatteryLevel: stopped
        )
    }

    // MARK: - Helpers

    private func scheduleNextTick(
        state liveState: AutomationNotifyOnBatteryLevelState,
        in fullState: AutomationState
    ) -> AutomationState {
        AutomationState(
            automation: fullState.automation!,
            status: .running,
            nextTaskRun: Date().addingTimeInterval(monitorInterval),
            notifyOnBatteryLevel: liveState
        )
    }

    private func describe(
        _ params: AutomationNotifyOnBatteryLevelParameters
    ) -> String {
        switch params.comparison {
        case .equalOrAbove: return "≥ \(params.targetBatteryLevel)%"
        case .equalOrBelow: return "≤ \(params.targetBatteryLevel)%"
        }
    }
}

// MARK: - Parameters & state

struct AutomationNotifyOnBatteryLevelParameters: Codable {
    /// Target battery level (0–100).
    var targetBatteryLevel: Int = 80
    var comparison: NotifyOnBatteryLevelPayload.Comparison = .equalOrAbove

    init() {}

    init(
        targetBatteryLevel: Int,
        comparison: NotifyOnBatteryLevelPayload.Comparison
    ) {
        self.targetBatteryLevel = targetBatteryLevel
        self.comparison = comparison
    }
}

enum AutomationNotifyOnBatteryLevelStopReason: String, Codable {
    case conditionMet
    case timedOut
    case cancelled
}

struct AutomationNotifyOnBatteryLevelState: Codable {
    var isStarted: Bool = false
    var startedAt: Date? = nil
    var lastTickAt: Date? = nil
    var lastBatteryLevel: Int? = nil
    var stopReason: AutomationNotifyOnBatteryLevelStopReason? = nil

    init() {}
}
