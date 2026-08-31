internal import Foundation

/// Keeps the server's silent-push wake window in step with what is running.
///
/// One window covers both subsystems: the push only says "wake up and check",
/// and the device decides what that means. `AutoResetChargingMode` is excluded —
/// it idles until its reset time, which the visible deadline push covers.
///
/// Best effort by nature: iOS throttles silent pushes, acknowledges nothing, and
/// stops them entirely after a force quit.
@MainActor
final class WakeWindowCoordinator {

    static let shared = WakeWindowCoordinator()

    /// Fixed id: one window per device, so a refresh replaces the previous
    /// registration instead of piling up rows.
    private static let scheduleId = "wake-window"

    /// Coarse on purpose: iOS budgets silent pushes anyway, so a tighter cadence
    /// burns that budget without landing more wakes.
    private static let cadenceMinutes = 15

    /// Short enough that an app which stops running automations stops receiving
    /// pushes soon after, long enough to survive a while offline.
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
