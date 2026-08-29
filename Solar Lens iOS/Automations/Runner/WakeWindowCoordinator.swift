internal import Foundation

/// Keeps the server's silent-push wake window in sync with what the app
/// actually has running (story #9 slice 4 / ADR-006).
///
/// One window covers both subsystems — a Battery → Car automation and any
/// active threshold monitors — because the push only says "wake up and check";
/// the device decides what that means. A second window would double the push
/// volume for no extra information.
///
/// Deliberately *not* registered for `AutoResetChargingMode`: that automation
/// does nothing at all between start and its reset time, and the reset itself
/// is covered by the far more reliable visible-push path.
///
/// Everything here is best effort. Silent pushes are throttled by iOS, give no
/// delivery feedback, need Background App Refresh, and stop entirely after a
/// force quit — they improve the average, they do not bound it.
@MainActor
final class WakeWindowCoordinator {

    static let shared = WakeWindowCoordinator()

    /// Fixed id: one window per device, so a refresh replaces the previous
    /// registration instead of piling up rows.
    private static let scheduleId = "wake-window"

    /// How often the server should nudge us. Kept coarse — iOS budgets silent
    /// pushes anyway, and a tighter cadence would burn that budget (and our
    /// execution count) without landing more wakes.
    private static let cadenceMinutes = 15

    /// How long a registration stays valid without renewal. Short enough that
    /// an app which stops running automations stops receiving pushes soon
    /// after, long enough to survive a device being offline for a while.
    private static let windowDuration: TimeInterval = 6 * 60 * 60

    /// Don't re-register on every 60 s tick; renew when the window is half
    /// spent.
    private static let renewAfter: TimeInterval = 3 * 60 * 60

    /// Persisted, not just in memory: a cold start must not look like "no
    /// window registered" and trigger a renewal on every launch.
    private static let registeredUntilKey =
        "SolarLens.wakeWindowRegisteredUntil"

    private var registeredUntil: Date? {
        get {
            AutomationSharedStore.defaults.object(
                forKey: Self.registeredUntilKey
            ) as? Date
        }
        set {
            let store = AutomationSharedStore.defaults
            guard let newValue else {
                store.removeObject(forKey: Self.registeredUntilKey)
                return
            }
            store.set(newValue, forKey: Self.registeredUntilKey)
        }
    }

    private var lastRefreshAt: Date?

    private init() {}

    /// Registers, renews or cancels the window to match the current state.
    /// Safe (and cheap) to call from ticks, scene-phase changes and whenever a
    /// monitor or automation starts or stops.
    func refresh(force: Bool = false) {
        let needsWindow =
            AutomationManager.shared.needsSilentWakeWindow
            || NotificationManager.shared.hasActiveMonitors

        guard needsWindow else {
            guard registeredUntil != nil || force else { return }
            registeredUntil = nil
            lastRefreshAt = nil
            Task {
                await WakeScheduleClient.cancel(
                    scheduleId: Self.scheduleId
                )
            }
            return
        }

        // Renew only when the current registration is running out (or we have
        // none) — otherwise a foregrounded app would call the API every minute.
        if !force, let until = registeredUntil,
            until.timeIntervalSinceNow > Self.renewAfter
        {
            return
        }
        if !force, let last = lastRefreshAt,
            Date().timeIntervalSince(last) < 60
        {
            return
        }

        let until = Date().addingTimeInterval(Self.windowDuration)
        lastRefreshAt = Date()
        Task {
            let result = await WakeScheduleClient.registerWindow(
                scheduleId: Self.scheduleId,
                cadenceMinutes: Self.cadenceMinutes,
                until: until
            )
            if case .registered = result {
                self.registeredUntil = until
            }
        }
    }

    /// Forgets the local bookkeeping — used when the device token changes, so
    /// the next refresh registers under the new token instead of assuming the
    /// old registration still stands.
    func invalidate() {
        registeredUntil = nil
        lastRefreshAt = nil
    }
}
