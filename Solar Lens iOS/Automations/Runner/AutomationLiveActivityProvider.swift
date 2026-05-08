internal import Foundation

/// Each `AutomationTask` that wants to surface a Live Activity conforms to
/// this protocol. The coordinator calls `makeLiveActivityContentState` after
/// every successful tick and pushes the returned value as a content update.
///
/// This is the *only* extension point widget extension code never has to
/// learn about: adding a new automation means a new conformance + a new
/// `Payload` case + a new card body view; the coordinator and the
/// `ActivityConfiguration` stay untouched.
protocol AutomationLiveActivityProvider {

    /// Map current task state → content state. Return `nil` to skip an
    /// update (e.g., before the run is fully started or when state is
    /// missing). Pure function — must not perform I/O.
    func makeLiveActivityContentState(
        state: AutomationState,
        parameters: AutomationParameters
    ) -> AutomationLiveActivityAttributes.ContentState?
}
