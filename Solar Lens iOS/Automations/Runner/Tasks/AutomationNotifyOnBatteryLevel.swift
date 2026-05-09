internal import Foundation
internal import UserNotifications

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

    /// Window inside which we trust the linear forecast enough to
    /// pre-schedule a "threshold due" calendar-triggered notification
    /// as a backstop. The forecast is just an extrapolation from the
    /// instantaneous (dis)charge rate and is unreliable further out
    /// (clouds clear, a load drops, …) — so we ONLY use it within this
    /// short window. The regular tick cadence is unaffected: we keep
    /// polling on `monitorInterval` (and whatever iOS gives us in BG)
    /// so the predictive notification is just a fallback, not a
    /// replacement for re-evaluating with fresh data.
    private let imminentForecastWindow: TimeInterval = 15 * 60

    /// Identifier for the pre-scheduled notification. Stable so we can
    /// replace / cancel it across ticks and on terminate.
    static let thresholdDueNotificationId =
        "automation.notifyOnBatteryLevel.thresholdDue"

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
        guard let overview = await fetchOverview(host: host),
              let batteryLevel = overview.currentBatteryLevel else {
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
        return scheduleNextTickConsideringForecast(
            host: host,
            params: params,
            overview: overview,
            liveState: live,
            in: state
        )
    }

    /// Picks the next tick time and, when the threshold is imminent,
    /// pre-arms a calendar-triggered fallback notification.
    ///
    /// `nextTaskRun` is **always** the regular monitor interval — the
    /// linear forecast is just an extrapolation from instantaneous
    /// (dis)charge rate and can be wildly wrong further out, so we
    /// never let it dictate when we re-check. The pre-scheduled
    /// notification is a pure backstop: if iOS doesn't grant us BG
    /// runtime in time and the forecast turns out right, the user
    /// still gets nudged at the predicted moment. If the forecast
    /// moves further out on the next tick, the notification is
    /// cancelled and re-scheduled (or dropped).
    private func scheduleNextTickConsideringForecast(
        host: any AutomationHost,
        params: AutomationNotifyOnBatteryLevelParameters,
        overview: OverviewData,
        liveState: AutomationNotifyOnBatteryLevelState,
        in fullState: AutomationState
    ) -> AutomationState {
        let regularNext = Date().addingTimeInterval(monitorInterval)

        // Capture the forecast on EVERY tick (not just within the
        // imminent window) so the in-app card and Live Activity can
        // display an ETA whenever it's available. The notification
        // backstop is still gated on the imminent window.
        let secondsToTarget = overview.forecastSeconds(
            toReach: params.targetBatteryLevel
        )

        var liveState = liveState
        liveState.forecastedTargetAt = secondsToTarget.flatMap {
            $0 > 0 ? Date().addingTimeInterval($0) : nil
        }

        if let s = secondsToTarget, s > 0, s <= imminentForecastWindow {
            scheduleThresholdDueNotification(
                at: Date().addingTimeInterval(s),
                params: params
            )
            host.logDebug(
                message:
                    "Notify on battery level: forecast threshold in \(Int(s))s — pre-scheduling backstop notification (regular tick cadence unchanged)"
            )
        } else {
            cancelThresholdDueNotification()
        }

        return AutomationState(
            automation: fullState.automation!,
            status: .running,
            nextTaskRun: regularNext,
            notifyOnBatteryLevel: liveState
        )
    }

    private func scheduleThresholdDueNotification(
        at date: Date,
        params: AutomationNotifyOnBatteryLevelParameters
    ) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Battery level reached")
        let comparator: String = {
            switch params.comparison {
            case .equalOrAbove: return "≥"
            case .equalOrBelow: return "≤"
            }
        }()
        content.body = String(
            localized:
                "Your house battery is forecast to reach \(comparator) \(params.targetBatteryLevel)% — open Solar Lens to see the live state."
        )
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        content.categoryIdentifier =
            AutomationNotificationDelegate.openHomeCategoryId
        content.userInfo = [
            AutomationNotificationDelegate.deepLinkUserInfoKey:
                "solarlens://home",
        ]

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: comps,
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: Self.thresholdDueNotificationId,
            content: content,
            trigger: trigger
        )

        Task {
            center.removePendingNotificationRequests(
                withIdentifiers: [Self.thresholdDueNotificationId]
            )
            try? await center.add(request)
        }
    }

    private func cancelThresholdDueNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: [Self.thresholdDueNotificationId]
            )
    }

    // MARK: - Telemetry

    private func fetchOverview(
        host: any AutomationHost
    ) async -> OverviewData? {
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
        guard overview.currentBatteryLevel != nil else {
            host.logError(
                message:
                    "Notify on battery level: no battery level reading from house battery; cannot tick"
            )
            return nil
        }
        return overview
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
        let overview = await fetchOverview(host: host)
        let level = overview?.currentBatteryLevel

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
//
// Codable model structs live in
// `Shared/Services/Automations/AutomationNotifyOnBatteryLevelParameters.swift`
// so the watch app can decode them over WatchConnectivity.
