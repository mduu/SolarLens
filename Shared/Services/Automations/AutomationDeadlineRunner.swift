internal import Foundation

/// Executes the *deadline* half of a time-bound automation, independently of
/// any UI, observation or app lifecycle.
///
/// Why this exists (story #9 / ADR-006): the same work has to run in two
/// processes — inside the app (`AutomationAutoResetChargingMode`, driven by
/// the foreground timer or a BG task) and inside the Notification Service
/// Extension, when the server's push arrives at the scheduled moment. Both
/// call into here, so the decision logic exists exactly once.
///
/// Everything the runner touches is process-agnostic: parameters/state passed
/// in, the Solar Manager API through `EnergyManager`, and a log sink that
/// carries the same localized messages and levels the app has always written.
/// No `UserNotifications`, no ActivityKit, no `@MainActor` — the NSE has none
/// of those (or must not block on them).
enum AutomationDeadlineRunner {

    /// What happened when the deadline was executed. The caller turns this
    /// into a notification text (NSE) or into `AutomationState` transitions
    /// plus the existing finished-notification (app).
    enum Outcome: Sendable, Equatable {
        /// The after-reset mode was applied successfully.
        case applied(modeTitle: String)
        /// The user had changed the charging mode manually since the run
        /// started — we deliberately left the charging station alone.
        case userOverride(currentModeTitle: String)
        /// Applying the mode failed; the charging station may still be on the
        /// active mode.
        case failed(message: String)
        /// The deadline has not been reached yet — nothing to do.
        case notDue(resetAt: Date)
    }

    /// Applies the after-reset charging mode if `resetAt` has been reached.
    ///
    /// Mirrors `AutomationAutoResetChargingMode.finishRun`, including the
    /// user-override check: if the charging station is no longer on the mode
    /// this automation set at start, the user changed it by hand and we must
    /// not overwrite that choice. A failing overview fetch is treated as "no
    /// override detected" so a transient network problem never blocks the
    /// normal reset.
    ///
    /// - Note: does **not** persist state; the caller decides what to write,
    ///   because app and extension keep different amounts of context.
    static func runAutoResetDeadline(
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

        // How late are we? This is the story #9 measurement: a run finished by
        // the push extension shows a few seconds, one that waited for a
        // background task or the user opening the app shows minutes to hours.
        // Local only — it lives in the automation log the user can read, and
        // is never sent anywhere.
        let lateness = Int(now.timeIntervalSince(params.resetAt))
        let latenessMessage: LocalizedStringResource =
            "Auto-reset Charging Mode: running \(lateness)s after the scheduled reset time"
        log(latenessMessage, .Debug)

        let currentMode: ChargingMode? = await {
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
        }()

        if let currentMode, currentMode != params.activeChargingMode {
            let currentName = String(localized: currentMode.localizedTitle)
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
}
