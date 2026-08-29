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
/// in, the Solar Manager API through `EnergyManager`, and a plain log sink.
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
        log: (String) -> Void = { _ in }
    ) async -> Outcome {
        guard now >= params.resetAt else {
            return .notDue(resetAt: params.resetAt)
        }

        let postName = String(
            localized: params.afterResetChargingMode.localizedTitle
        )

        let currentMode: ChargingMode? = await {
            do {
                let overview = try await energyManager.fetchOverviewData(
                    lastOverviewData: nil
                )
                return overview.chargingStations
                    .first { $0.id == params.chargingDeviceId }?
                    .chargingMode
            } catch {
                log(
                    "Auto-reset Charging Mode: pre-reset overview fetch failed (\(error.localizedDescription)) — skipping user-override check"
                )
                return nil
            }
        }()

        if let currentMode, currentMode != params.activeChargingMode {
            let currentName = String(localized: currentMode.localizedTitle)
            log(
                "Auto-reset Charging Mode: user override detected — charging station is on \(currentName), expected the active mode. Leaving station as configured by the user, NOT applying \(postName)."
            )
            return .userOverride(currentModeTitle: currentName)
        }

        do {
            _ = try await energyManager.setCarChargingMode(
                sensorId: params.chargingDeviceId,
                carCharging: ControlCarChargingRequest(
                    chargingMode: params.afterResetChargingMode
                )
            )
        } catch {
            log(
                "Auto-reset Charging Mode: failed to switch charging station to \(postName): \(error.localizedDescription) — charging station may stay on the active mode. Please check the Solar Manager app."
            )
            return .failed(message: error.localizedDescription)
        }

        log(
            "Auto-reset Charging Mode: reset completed — charging station switched to \(postName)"
        )
        return .applied(modeTitle: postName)
    }
}
