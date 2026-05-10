import ActivityKit
internal import Foundation
import OSLog

/// Owns the iOS `Activity<AutomationLiveActivityAttributes>` for the
/// currently-running automation.
///
/// Lifecycle hooks (called by `AutomationManager`):
/// - `start(automation:)`         — request a new activity
/// - `update(state:parameters:)`  — push a content update (lazy-starts the
///                                  activity if one didn't get requested at
///                                  start time, e.g. because the initial
///                                  content state wasn't ready yet)
/// - `end(state:parameters:)`     — end the activity with a final snapshot
///
/// Resilient to:
/// - Live Activities being disabled at the OS level
///   (`areActivitiesEnabled == false`) — every method becomes a no-op and
///   logs the reason so the cause is visible in Console.
/// - The app being killed mid-run — on init we re-acquire any dangling
///   active activity matching our attributes type so subsequent updates
///   land on it instead of starting a duplicate.
/// - Stale dismissed activities from a previous run still occupying the
///   system slot — `start()` flushes any non-active ones before
///   requesting a new activity. Without this, restarting an automation
///   within the post-stop linger window (`.after(.now + 120)`) caused
///   `Activity.request` to either fail silently or get visually masked
///   by the lingering one.
@MainActor
final class AutomationLiveActivityCoordinator {

    static let shared = AutomationLiveActivityCoordinator()

    private static let logger = Logger(
        subsystem: "com.marcduerst.SolarManagerWatch",
        category: "LiveActivity"
    )

    private var activity: Activity<AutomationLiveActivityAttributes>?

    private init() {
        Task {
            await reattachOrphan()
        }
    }

    // MARK: - Lifecycle

    func start(
        automation: Automation,
        state: AutomationState,
        parameters: AutomationParameters
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            Self.logger.notice(
                "Live Activities disabled at OS level — skipping start. Settings → Notifications → Solar Lens → Live Activities."
            )
            return
        }

        if let active = activity, active.activityState == .active {
            Self.logger.debug(
                "Activity already active — forwarding to update()."
            )
            update(state: state, parameters: parameters)
            return
        }

        // Drop any lingering reference (likely an activity that's already
        // .ended / .dismissed; the system will clean it up). Then flush
        // any stragglers from earlier runs so the new request gets a
        // clean slot.
        activity = nil

        Task {
            await endStaleActivities(reason: "before new start")
            await MainActor.run {
                requestActivity(
                    automation: automation,
                    state: state,
                    parameters: parameters,
                    origin: "start"
                )
            }
        }
    }

    func update(
        state: AutomationState,
        parameters: AutomationParameters
    ) {
        // Lazy-start safety net: if the activity wasn't successfully
        // requested at start time (e.g. because the initial content state
        // was nil before the first tick wrote any data), try again now.
        if activity == nil || activity?.activityState != .active {
            guard let automation = state.automation else { return }
            guard ActivityAuthorizationInfo().areActivitiesEnabled else {
                return
            }
            activity = nil
            Task {
                await endStaleActivities(reason: "before lazy start")
                await MainActor.run {
                    requestActivity(
                        automation: automation,
                        state: state,
                        parameters: parameters,
                        origin: "update (lazy start)"
                    )
                }
            }
            return
        }

        guard let activity,
              let automation = state.automation,
              let task = automation.getAutomationTask()
                as? AutomationLiveActivityProvider,
              let content = task.makeLiveActivityContentState(
                state: state, parameters: parameters
              )
        else {
            return
        }

        Task {
            await activity.update(
                ActivityContent(
                    state: content,
                    staleDate: Date().addingTimeInterval(5 * 60)
                )
            )
            Self.logger.debug("Activity content updated.")
        }
    }

    /// Awaitable. Callers that run inside a constrained background
    /// runtime budget (BGAppRefreshTask, scenePhase observers, the
    /// cancel intent's Task) **must** `await` this so the underlying
    /// `Activity.end(...)` request reaches the system before iOS
    /// suspends the process — otherwise the Live Activity stays on
    /// the Lock Screen until the user manually clears it.
    func end(
        state: AutomationState,
        parameters: AutomationParameters
    ) async {
        let final: AutomationLiveActivityAttributes.ContentState? = {
            guard let automation = state.automation,
                  let task = automation.getAutomationTask()
                    as? AutomationLiveActivityProvider
            else { return nil }
            return task.makeLiveActivityContentState(
                state: state, parameters: parameters
            )
        }()

        let tracked = activity
        self.activity = nil

        if let tracked {
            if let final {
                await tracked.end(
                    ActivityContent(state: final, staleDate: nil),
                    dismissalPolicy: .after(.now + 120)
                )
            } else {
                await tracked.end(nil, dismissalPolicy: .immediate)
            }
            Self.logger.notice("Activity ended (id=\(tracked.id)).")
        } else {
            Self.logger.debug(
                "end() called with no tracked activity — falling through to system-level cleanup."
            )
        }

        // Defensive: end any other system activities of our attributes
        // type. Without this, an orphan (e.g. created in a previous
        // process lifetime, or surviving a scenePhase / BGTask race
        // where our tracked reference was already nil) keeps the LA
        // stuck on the Lock Screen indefinitely. `start()` already
        // does the same flush before requesting a new activity; doing
        // it here too closes the symmetry.
        await endStaleActivities(reason: "after explicit end")
    }

    // MARK: - Internal

    private func requestActivity(
        automation: Automation,
        state: AutomationState,
        parameters: AutomationParameters,
        origin: String
    ) {
        guard let task = automation.getAutomationTask()
                as? AutomationLiveActivityProvider else {
            Self.logger.error(
                "Automation \(String(describing: automation)) does not conform to AutomationLiveActivityProvider."
            )
            return
        }
        guard let initial = task.makeLiveActivityContentState(
            state: state, parameters: parameters
        ) else {
            Self.logger.debug(
                "No initial content state from \(origin) — will retry on next update()."
            )
            return
        }

        let beforeCount = Activity<AutomationLiveActivityAttributes>
            .activities.count
        Self.logger.notice(
            "Requesting activity via \(origin); existing system activities of this type: \(beforeCount)"
        )

        do {
            let attributes = AutomationLiveActivityAttributes(
                automation: automation
            )
            let content = ActivityContent(
                state: initial,
                staleDate: Date().addingTimeInterval(5 * 60)
            )
            activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            Self.logger.notice(
                "Activity requested via \(origin). id=\(self.activity?.id ?? "?")"
            )
        } catch {
            Self.logger.error(
                "Activity.request failed via \(origin): \(error.localizedDescription)"
            )
        }
    }

    /// Ends every system activity of our attributes type, regardless of
    /// state. Used right before requesting a new activity so we don't
    /// fight a lingering `.dismissed` activity for the visible slot.
    private func endStaleActivities(reason: String) async {
        let stragglers = Activity<AutomationLiveActivityAttributes>.activities
        guard !stragglers.isEmpty else { return }
        Self.logger.notice(
            "Ending \(stragglers.count) stale activit(ies) (\(reason))."
        )
        for stragglerActivity in stragglers {
            await stragglerActivity.end(
                nil, dismissalPolicy: .immediate
            )
        }
    }

    // MARK: - Orphan recovery

    private func reattachOrphan() async {
        var attached = false
        for existing in Activity<AutomationLiveActivityAttributes>.activities {
            // Only re-attach to genuinely live activities. Dismissed /
            // ended ones can't be updated meaningfully and would mask
            // a fresh `start()` that follows.
            if existing.activityState == .active && !attached {
                await MainActor.run { self.activity = existing }
                attached = true
                Self.logger.notice(
                    "Reattached existing active activity id=\(existing.id)"
                )
            } else {
                await existing.end(nil, dismissalPolicy: .immediate)
                Self.logger.debug(
                    "Cleared non-active activity id=\(existing.id) state=\(String(describing: existing.activityState))"
                )
            }
        }
    }
}
