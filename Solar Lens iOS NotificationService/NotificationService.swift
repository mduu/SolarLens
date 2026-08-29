import UserNotifications
internal import Foundation

/// Notification Service Extension — the piece that makes a *scheduled*
/// automation actually happen (story #9 / ADR-006).
///
/// The Solar Lens server sends a visible alert push with `mutable-content: 1`
/// at the automation's end time. iOS launches this extension **even when the
/// app was force-quit**, gives it ~30 s, and shows whatever content we hand
/// back. So we:
///
/// 1. read the automation state the app persisted into the App Group,
/// 2. run the deadline logic on-device (Solar Manager token from the shared
///    Keychain — nothing about the automation ever reaches our server),
/// 3. leave an outcome record for the app to reconcile, and
/// 4. rewrite the notification text so what the user reads is what happened.
///
/// If anything goes wrong or takes too long, iOS falls back to the server's
/// default payload text — which is worded to stay truthful in that case
/// ("reset time reached…"), never claiming success.
final class NotificationService: UNNotificationServiceExtension {

    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNMutableNotificationContent?
    /// Guards against handing the content back twice (normal completion racing
    /// the expiration handler) — the second call is ignored by iOS but the
    /// double state write would not be.
    private var didDeliver = false

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) ->
            Void
    ) {
        self.contentHandler = contentHandler
        let mutable = request.content.mutableCopy()
            as? UNMutableNotificationContent
        bestAttemptContent = mutable

        let parsed = AutomationPushPayload.parse(
            userInfo: request.content.userInfo
        )

        guard parsed.kind == .automationDeadline else {
            // Not ours (or a kind a future server version introduced) —
            // deliver untouched.
            deliver()
            return
        }

        Task {
            await self.runDeadline(automation: parsed.automation)
            self.deliver()
        }
    }

    /// iOS is about to kill us. Whatever we have is what the user sees.
    override func serviceExtensionTimeWillExpire() {
        AutomationSharedStore.releaseTickLease()
        deliver()
    }

    // MARK: - Work

    private func runDeadline(automation: Automation?) async {
        guard let state = AutomationSharedStore.activeState,
            let parameters = AutomationSharedStore.activeParameters,
            let running = state.automation
        else {
            // The app already finished the run (its own tick beat the push,
            // or the user cancelled). Say so instead of implying we did
            // something.
            setBody(
                String(
                    localized:
                        "This automation has already finished. Open Solar Lens for details."
                )
            )
            return
        }

        guard automation == nil || automation == running,
            running == .AutoResetChargingMode,
            let params = parameters.autoResetChargingMode
        else {
            // A time-bound automation we don't know how to run here. Leave
            // the server's default text; the app's own runner handles it.
            return
        }

        // The app may be in the foreground and ticking right now. Only one of
        // us may call the charging-mode API.
        guard AutomationSharedStore.acquireTickLease() else {
            setBody(
                String(
                    localized:
                        "Solar Lens is already applying this change. Open the app for details."
                )
            )
            return
        }
        defer { AutomationSharedStore.releaseTickLease() }

        let outcome = await AutomationDeadlineRunner.runAutoResetDeadline(
            parameters: params,
            energyManager: SolarManager.shared,
            log: { message in
                AutomationLogWriter.append(message, level: .Debug)
            }
        )

        switch outcome {
        case .notDue(let resetAt):
            // Push arrived early (clock skew / an old schedule). Don't touch
            // the charging station; let the app's runner deal with it.
            AutomationLogWriter.append(
                "Push arrived before the reset time (\(resetAt)) — nothing done.",
                level: .Debug
            )

        case .applied(let modeTitle):
            finish(
                state: state,
                kind: .applied,
                detail: modeTitle,
                stationId: params.chargingDeviceId,
                modeRaw: params.afterResetChargingMode.rawValue
            )
            AutomationLogWriter.append(
                "Auto-reset Charging Mode: reset completed via push — charging station switched to \(modeTitle)",
                level: .Success
            )
            setTitle(String(localized: "Auto-reset Charging Mode finished"))
            setBody(
                String(localized: "Charging mode reset to \(modeTitle).")
            )

        case .userOverride(let currentModeTitle):
            finish(
                state: state,
                kind: .userOverride,
                detail: currentModeTitle,
                stationId: nil,
                modeRaw: nil
            )
            AutomationLogWriter.append(
                "Auto-reset Charging Mode: user override detected via push — charging station left on \(currentModeTitle)",
                level: .Info
            )
            setTitle(String(localized: "Auto-reset Charging Mode cancelled"))
            setBody(
                String(
                    localized:
                        "You changed the charging mode manually. The automation stopped and left the charging station on \(currentModeTitle)."
                )
            )

        case .failed(let message):
            finish(
                state: state,
                kind: .failed,
                detail: message,
                stationId: nil,
                modeRaw: nil
            )
            AutomationLogWriter.append(
                "Auto-reset Charging Mode: reset via push failed — \(message)",
                level: .Error
            )
            setTitle(String(localized: "Auto-reset Charging Mode stopped"))
            setBody(
                String(
                    localized:
                        "Couldn't apply the charging-mode change. Please verify the charging station state in the Solar Manager app."
                )
            )
        }
    }

    /// Clears the shared active state and records what happened, so the app
    /// tears down the Live Activity and refreshes its UI on next launch
    /// instead of running the automation a second time.
    private func finish(
        state: AutomationState,
        kind: AutomationExternalOutcome.Kind,
        detail: String?,
        stationId: String?,
        modeRaw: Int?
    ) {
        AutomationSharedStore.externalOutcome = AutomationExternalOutcome(
            automation: state.automation ?? .AutoResetChargingMode,
            kind: kind,
            detail: detail,
            chargingStationId: stationId,
            chargingModeRaw: modeRaw
        )
        AutomationSharedStore.clearActiveAutomation()

        // The app scheduled a local "open Solar Lens to apply…" notification
        // as a fallback for exactly this moment. We just did the work, so
        // that message would be wrong — pull it.
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: [
                    AutomationSharedStore.resetDueFallbackNotificationId
                ]
            )
    }

    // MARK: - Content helpers

    private func setTitle(_ title: String) {
        bestAttemptContent?.title = title
    }

    private func setBody(_ body: String) {
        bestAttemptContent?.body = body
    }

    private func deliver() {
        guard !didDeliver, let contentHandler else { return }
        didDeliver = true
        contentHandler(bestAttemptContent ?? UNNotificationContent())
    }
}
