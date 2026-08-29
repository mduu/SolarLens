import UIKit
internal import UserNotifications

/// Owns the app's APNs registration (story #9 / ADR-006).
///
/// The token is the only identifier our server ever sees. We ask for it as
/// soon as the user has granted notification permission — never before, so the
/// system permission prompt stays tied to the moment the user starts an
/// automation or a monitor, exactly as it is today.
///
/// Tokens rotate (restore from backup, reinstall, occasionally on OS update),
/// so whenever a new one arrives we re-register the active automation's
/// deadline under it and drop the stale registration.
/// Everything here is static on purpose: `@UIApplicationDelegateAdaptor`
/// creates its *own* instance of this class, so an instance-level singleton
/// would receive the app's configuration while the system delivered the
/// callbacks to a different object — the token would silently never be
/// forwarded.
final class PushRegistrar: NSObject, UIApplicationDelegate {

    /// Set by the app so a token change can re-register whatever is running.
    /// Kept as a closure to avoid a dependency from `Shared/` back into the
    /// app's automation runner.
    static var onTokenChanged: ((String) -> Void)?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions:
            [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        Self.registerIfAuthorized()
        return true
    }

    /// Registers for remote notifications, but only once the user has actually
    /// allowed notifications — asking earlier would either fail silently or
    /// (worse) prompt out of context.
    static func registerIfAuthorized() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional
            else { return }
            Task { @MainActor in
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        let previous = WakeScheduleClient.deviceToken
        guard token != previous else { return }

        // The old token can no longer be delivered to; drop its schedules
        // before we start using the new one, so the server does not keep dead
        // rows around until they expire.
        if previous != nil {
            Task { await WakeScheduleClient.forgetDevice() }
        }
        WakeScheduleClient.deviceToken = token
        Task { @MainActor in
            // The previous registrations died with the old token.
            WakeWindowCoordinator.shared.invalidate()
            WakeWindowCoordinator.shared.refresh()
        }
        Self.onTokenChanged?(token)
    }

    /// Silent wake push (story #9 slice 4): the server nudges us on a coarse
    /// cadence while a Battery → Car run or a threshold monitor is active.
    ///
    /// iOS gives us a few seconds here and holds the completion handler
    /// against our background budget, so we drain and return promptly.
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler:
            @escaping (UIBackgroundFetchResult) -> Void
    ) {
        let parsed = AutomationPushPayload.parse(userInfo: userInfo)
        guard parsed.kind == .wake else {
            completionHandler(.noData)
            return
        }
        Task { @MainActor in
            await AutomationManager.shared.handleRemoteWake()
            completionHandler(.newData)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        // Not fatal: without a token we simply never register a wake-up and
        // the automation falls back to BG tasks plus the local notification.
        AutomationLogManager.shared.log(
            .init(
                message:
                    "Push registration failed (\(error.localizedDescription)) — scheduled automations fall back to background execution",
                level: .Debug
            )
        )
    }
}
