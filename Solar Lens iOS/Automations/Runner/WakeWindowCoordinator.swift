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

    /// The most recent fire-and-forget refresh, so a caller that needs the
    /// work finished can wait for one already running instead of racing it
    /// into the 60-second guard below.
    private var pending: Task<Void, Never>?

    /// Fire-and-forget form, for callers that stay alive while it runs —
    /// scene-phase changes, ticks, a monitor or automation starting or
    /// stopping.
    ///
    /// Do **not** use this from a background wake. See `refreshAndWait`.
    func refresh(force: Bool = false) {
        pending = Task { await performRefresh(force: force) }
    }

    /// Registers, renews or cancels the window to match the current state, and
    /// does not return until the server has answered.
    ///
    /// The silent-push handler must use this one. It used to call the
    /// fire-and-forget form and return; iOS then invoked the completion
    /// handler and suspended the process with the PUT still in flight, so the
    /// connection died mid-body. The server logged 499 and
    /// "Unexpected end of request content" — 219 of them against 88 that
    /// completed. Worse than noise: `registeredUntil` is only set on success,
    /// so every cut-off attempt made the next wake try again and be cut off
    /// too. Window renewal only ever succeeded while the app was foregrounded.
    ///
    /// Waits for any in-flight fire-and-forget refresh first: the same
    /// background wake also runs the monitors, and persisting those kicks off
    /// a refresh of its own. Without this, that one could win the race, do the
    /// call, and leave this one to early-return — putting us straight back to
    /// an unawaited request.
    func refreshAndWait(force: Bool = false) async {
        if let pending {
            await pending.value
            self.pending = nil
        }
        await performRefresh(force: force)
    }

    private func performRefresh(force: Bool) async {
        let needsWindow =
            AutomationManager.shared.needsSilentWakeWindow
            || NotificationManager.shared.hasActiveMonitors

        guard needsWindow else {
            guard registeredUntil != nil || force else { return }
            registeredUntil = nil
            lastRefreshAt = nil
            await WakeScheduleClient.cancel(scheduleId: Self.scheduleId)
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
        let result = await WakeScheduleClient.registerWindow(
            scheduleId: Self.scheduleId,
            cadenceMinutes: Self.cadenceMinutes,
            until: until
        )
        if case .registered = result {
            registeredUntil = until
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
