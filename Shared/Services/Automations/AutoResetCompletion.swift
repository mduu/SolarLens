internal import Foundation

/// Finishes an Auto-reset Charging Mode run: applies the after-reset mode once
/// the reset time is reached, unless the user changed the mode by hand.
///
/// Lives here because two processes need it — the app and the Notification
/// Service Extension, which runs it when the scheduled push arrives (ADR-006).
/// Hence no UI, no `@MainActor`, no persistence: the caller decides what to
/// store.
enum AutoResetCompletion {

    enum Outcome: Sendable, Equatable {
        case applied(modeTitle: String)
        /// User changed the mode themselves — the station was left alone.
        case userOverride(currentModeTitle: String)
        case failed(message: String)
        case notDue(resetAt: Date)
    }

    static func complete(
        parameters params: AutomationAutoResetChargingModeParameters,
        energyManager: any EnergyManager,
        now: Date = Date(),
        log: (LocalizedStringResource, AutomationLogMessageLevel) -> Void =
            { _, _ in }
    ) async -> Outcome {
        guard now >= params.resetAt else {
            return .notDue(resetAt: params.resetAt)
        }

        let postName = String(
            localized: params.afterResetChargingMode.localizedTitle
        )

        // Seconds late is how we tell a push-driven finish (a few seconds)
        // from one that waited for a background task (minutes to hours).
        // Local only — it goes into the log the user can read.
        let secondsLate = Int(now.timeIntervalSince(params.resetAt))
        let lateness: LocalizedStringResource =
            "Auto-reset Charging Mode: running \(secondsLate)s after the scheduled reset time"
        log(lateness, .Debug)

        let modeSetByUser = await currentChargingMode(
            params: params, energyManager: energyManager, log: log
        )

        if let modeSetByUser, modeSetByUser != params.activeChargingMode {
            let currentName = String(localized: modeSetByUser.localizedTitle)
            let message: LocalizedStringResource =
                "Auto-reset Charging Mode: user override detected — charging station is on \(currentName), expected the active mode. Leaving station as configured by the user, NOT applying \(postName)."
            log(message, .Info)
            return .userOverride(currentModeTitle: currentName)
        }

        let switching: LocalizedStringResource =
            "Auto-reset Charging Mode: reset time reached — switching charging station to \(postName)"
        log(switching, .Debug)

        do {
            _ = try await energyManager.setCarChargingMode(
                sensorId: params.chargingDeviceId,
                carCharging: ControlCarChargingRequest(
                    chargingMode: params.afterResetChargingMode
                )
            )
        } catch {
            let message: LocalizedStringResource =
                "Auto-reset Charging Mode: failed to switch charging station to \(postName): \(error.localizedDescription) — charging station may stay on the active mode. Please check the Solar Manager app."
            log(message, .Error)
            return .failed(message: error.localizedDescription)
        }

        let completed: LocalizedStringResource =
            "Auto-reset Charging Mode: reset completed — charging station switched to \(postName)"
        log(completed, .Info)
        return .applied(modeTitle: postName)
    }

    /// The station's mode right now, or `nil` when we could not ask — a
    /// network blip must not block the reset, so "unknown" counts as
    /// "no override".
    private static func currentChargingMode(
        params: AutomationAutoResetChargingModeParameters,
        energyManager: any EnergyManager,
        log: (LocalizedStringResource, AutomationLogMessageLevel) -> Void
    ) async -> ChargingMode? {
        do {
            let overview = try await energyManager.fetchOverviewData(
                lastOverviewData: nil
            )
            return overview.chargingStations
                .first { $0.id == params.chargingDeviceId }?
                .chargingMode
        } catch {
            let message: LocalizedStringResource =
                "Auto-reset Charging Mode: pre-reset overview fetch failed (\(error.localizedDescription)) — skipping user-override check"
            log(message, .Debug)
            return nil
        }
    }
}
