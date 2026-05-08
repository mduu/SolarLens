internal import UserNotifications
import UIKit

/// Allows automation notifications to surface as a banner + sound even
/// while Solar Lens is in the foreground, and routes notification taps
/// (default + per-action) to the appropriate place in the app via the
/// app's deep-link scheme (`solarlens://…`).
///
/// Without this, iOS suppresses banner display for foreground apps, so a
/// graceful "automation finished" notification fires silently — the user
/// only sees it if they happen to be on the Lock Screen at the moment of
/// completion. The cancel notification *appeared* to "work" because
/// Cancel is most often triggered from the Lock Screen Live Activity,
/// where the app is backgrounded and the default banner behaviour
/// applies.
///
/// We always return `[.banner, .sound, .list]` from `willPresent`. Tap
/// handling reads the notification's `userInfo` for a `"deepLink"` URL
/// and `UIApplication.open`'s it back through the app's URL scheme,
/// which `ContentView`'s `.onOpenURL` then dispatches to the correct
/// tab.
final class AutomationNotificationDelegate: NSObject,
    UNUserNotificationCenterDelegate {

    static let shared = AutomationNotificationDelegate()

    /// Notification category for the "open the app on the main screen"
    /// action. Used by the Notify-on-battery-level automation. Adding
    /// new categories here is a one-line change.
    static let openHomeCategoryId =
        "automation.openHome"

    /// Identifier for the "Open Solar Lens" action exposed on the
    /// `openHomeCategoryId` notification.
    static let openAppActionId =
        "automation.openApp"

    /// `userInfo` key used to carry the destination deep-link URL
    /// alongside the notification content.
    static let deepLinkUserInfoKey = "deepLink"

    private override init() { super.init() }

    /// Registers all known notification categories. Must be called on
    /// app launch (idempotent). Calling on every launch is fine — the
    /// system overwrites the previous list.
    func registerCategories() {
        let openAction = UNNotificationAction(
            identifier: Self.openAppActionId,
            title: String(localized: "Open Solar Lens"),
            options: [.foreground]
        )
        let openHomeCategory = UNNotificationCategory(
            identifier: Self.openHomeCategoryId,
            actions: [openAction],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current()
            .setNotificationCategories([openHomeCategory])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (
            UNNotificationPresentationOptions
        ) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Both the default tap (`actionIdentifier ==
        // UNNotificationDefaultActionIdentifier`) and our explicit
        // "Open Solar Lens" action funnel into the same deep-link
        // dispatch — they both mean "the user wants to be in the app".
        let userInfo = response.notification.request.content.userInfo
        if let urlString = userInfo[Self.deepLinkUserInfoKey] as? String,
           let url = URL(string: urlString) {
            Task { @MainActor in
                UIApplication.shared.open(url)
            }
        }
        completionHandler()
    }
}
