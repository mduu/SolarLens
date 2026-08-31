import UIKit
internal import UserNotifications

/// Owns the app's APNs registration.
///
/// The token is the only identifier our server sees. We ask for it once
/// notifications are granted — never before, so the system prompt stays tied to
/// the moment the user starts an automation.
///
/// State is static because `@UIApplicationDelegateAdaptor` instantiates its own
/// delegate — instance state would be set on one object and delivered to another.
final class PushRegistrar: NSObject, UIApplicationDelegate {

    /// Lets a token change re-register whatever is running, without a dependency
    /// from `Shared/` back into the automation runner.
    static var onTokenChanged: ((String) -> Void)?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions:
            [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        Self.registerIfAuthorized()
        return true
    }

    /// No-op until the user has actually allowed notifications — asking earlier
    /// fails silently or prompts out of context.
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

        #if DEBUG
            // Needed to send a test push by hand (Push Notifications Console).
            // Before the unchanged-guard, so it shows on every launch, and
            // never in a release build.
            print("[SolarLens] APNs device token: \(token)")
        #endif

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

    /// Silent wake push: the server nudges us while a Battery → Car run or a
    /// monitor is active. iOS holds the completion handler against our background
    /// budget, so drain and return promptly.
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
                level: .Info
            )
        )
    }
}
