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
final class PushRegistrar: NSObject, UIApplicationDelegate {

    static let shared = PushRegistrar()

    /// Set by the app so a token change can re-register whatever is running.
    /// Kept as a closure to avoid a dependency from `Shared/` back into the
    /// app's automation runner.
    var onTokenChanged: ((String) -> Void)?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions:
            [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        registerIfAuthorized()
        return true
    }

    /// Registers for remote notifications, but only once the user has actually
    /// allowed notifications — asking earlier would either fail silently or
    /// (worse) prompt out of context.
    func registerIfAuthorized() {
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
        onTokenChanged?(token)
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
