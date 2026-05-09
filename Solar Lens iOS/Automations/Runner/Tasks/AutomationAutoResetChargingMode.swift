internal import Foundation
internal import UserNotifications

/// Automation: switch the wallbox to a user-chosen charging mode now, sleep
/// until a user-chosen reset date, then switch the wallbox to a second
/// user-chosen charging mode.
///
/// Cadence is fundamentally simpler than `AutomationBatteryToCar`:
/// only two API calls, separated by a long wait. The runner schedules
/// `nextTaskRun = params.resetAt` so the foreground 60 s timer + BG refresh
/// keep checking and find nothing due until the date is reached. No
/// per-second telemetry, no ramp logic, no soft-floor predictions.
final class AutomationAutoResetChargingMode: AutomationTask {
    public static let shared = AutomationAutoResetChargingMode()

    let automationName: LocalizedStringResource = "Auto-reset Charging Mode"

    /// Charging modes offered to the user in the setup sheet.
    /// Source of truth lives in
    /// `Shared/Services/Automations/AutoResetChargingModeOptions.swift`
    /// so the watch setup sheet can use the same list.
    static let selectableModes: [ChargingMode] =
        AutoResetChargingModeOptions.selectableModes

    /// Identifier for the local "reset is due now" notification scheduled
    /// at start time. Stable so we can cancel it on graceful finish or
    /// user cancel. See the `scheduleResetDueNotification` /
    /// `cancelResetDueNotification` helpers below.
    static let resetDueNotificationId =
        "automation.autoResetChargingMode.due"

    func run(
        host: any AutomationHost,
        parameters: AutomationParameters,
        state: AutomationState
    ) async throws -> AutomationState {
        guard let params = parameters.autoResetChargingMode,
              let liveState0 = state.autoResetChargingMode else {
            host.logError(
                message: "Auto-reset Charging Mode: missing parameters"
            )
            host.logFailure()
            return state.failed()
        }

        // First tick: capture the previous mode and apply the active mode.
        if !liveState0.isStarted {
            return await startRun(
                host: host,
                parameters: params,
                state: state
            )
        }

        // Reset time reached → apply the post-reset mode and finish.
        if Date() >= params.resetAt {
            return await finishRun(
                host: host,
                parameters: params,
                state: state,
                liveState: liveState0
            )
        }

        // Not yet — re-arm the wake-up. Idempotent: same date each time.
        return AutomationState(
            automation: state.automation!,
            status: .running,
            nextTaskRun: params.resetAt,
            autoResetChargingMode: liveState0
        )
    }

    // MARK: - Start

    private func startRun(
        host: any AutomationHost,
        parameters params: AutomationAutoResetChargingModeParameters,
        state: AutomationState
    ) async -> AutomationState {
        let activeName = String(
            localized: params.activeChargingMode.localizedTitle
        )
        let postName = String(
            localized: params.afterResetChargingMode.localizedTitle
        )
        host.logDebug(
            message: "Auto-reset Charging Mode: starting"
        )

        do {
            _ = try await host.energyManager.setCarChargingMode(
                sensorId: params.chargingDeviceId,
                carCharging: ControlCarChargingRequest(
                    chargingMode: params.activeChargingMode
                )
            )
        } catch {
            host.logError(
                message:
                    "Auto-reset Charging Mode: failed to set wallbox to \(activeName): \(error.localizedDescription)"
            )
            host.logFailure()
            return state.failed()
        }

        host.logInfo(
            message:
                "Auto-reset Charging Mode: started — wallbox set to \(activeName), will reset to \(postName) at \(formatted(params.resetAt))"
        )

        // Schedule a local notification at the reset time. Without this,
        // iOS may not give us BG runtime around `resetAt` and the user
        // would see the LA countdown reach 0 with the wallbox still on
        // the active mode. The notification reliably fires at the
        // user-chosen moment; tapping it brings the app to foreground,
        // which immediately runs a tick that finishes the run.
        scheduleResetDueNotification(
            at: params.resetAt,
            afterModeName: postName
        )

        var live = AutomationAutoResetChargingModeState()
        live.isStarted = true
        live.startedAt = Date()
        live.appliedActiveModeAt = Date()
        live.activeChargingModeAtStart = params.activeChargingMode

        return AutomationState(
            automation: state.automation!,
            status: .running,
            nextTaskRun: params.resetAt,
            autoResetChargingMode: live
        )
    }

    // MARK: - Reset-due notification

    private func scheduleResetDueNotification(
        at date: Date,
        afterModeName: String
    ) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Auto-reset Charging Mode")
        content.body = String(
            localized:
                "Reset time reached — open Solar Lens to apply \(afterModeName) to the wallbox."
        )
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: comps,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: Self.resetDueNotificationId,
            content: content,
            trigger: trigger
        )

        Task {
            // Authorization is requested when the user starts an
            // automation — the system silently no-ops if already granted.
            _ = try? await center.requestAuthorization(
                options: [.alert, .sound, .timeSensitive]
            )
            try? await center.add(request)
        }
    }

    // MARK: - Finish (reset time reached)

    private func finishRun(
        host: any AutomationHost,
        parameters params: AutomationAutoResetChargingModeParameters,
        state: AutomationState,
        liveState: AutomationAutoResetChargingModeState
    ) async -> AutomationState {
        let postName = String(
            localized: params.afterResetChargingMode.localizedTitle
        )
        host.logDebug(
            message:
                "Auto-reset Charging Mode: reset time reached — switching wallbox to \(postName)"
        )

        do {
            _ = try await host.energyManager.setCarChargingMode(
                sensorId: params.chargingDeviceId,
                carCharging: ControlCarChargingRequest(
                    chargingMode: params.afterResetChargingMode
                )
            )
        } catch {
            host.logError(
                message:
                    "Auto-reset Charging Mode: failed to switch wallbox to \(postName): \(error.localizedDescription) — wallbox may stay on the active mode. Please check the Solar Manager app."
            )
            // We still terminate; the user gets a "failed" notification path.
            host.logFailure()
            return state.failed()
        }

        var stopped = liveState
        stopped.appliedAfterResetModeAt = Date()
        stopped.stopReason = .resetCompleted

        host.logInfo(
            message:
                "Auto-reset Charging Mode: reset completed — wallbox switched to \(postName)"
        )
        host.logSuccess()

        return AutomationState(
            automation: state.automation!,
            status: .finishedSuccessful,
            nextTaskRun: nil,
            autoResetChargingMode: stopped
        )
    }

    private func formatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }
}

// MARK: - Parameters & state
//
// Codable model structs live in
// `Shared/Services/Automations/AutomationAutoResetChargingModeParameters.swift`
// so the watch app can decode them over WatchConnectivity.
