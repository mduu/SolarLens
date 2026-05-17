import Observation

/// SwiftUI-facing observable surface for the watch-side automation
/// snapshot. Deliberately the *only* observable piece in the
/// automation feature on watchOS — it owns no Foundation delegates,
/// no NSObject conformance, no actor isolation other than `@MainActor`.
///
/// The WCSession side lives in `AutomationWatchSession`, which writes
/// into `snapshot` here via a single `Task { @MainActor in … }`. This
/// split is intentional: prior versions mixed `@Observable`,
/// `@MainActor`, `NSObject`, and `WCSessionDelegate` in one singleton
/// and produced an intermittent watchOS freeze on real devices after
/// hours of use. Keeping the observable surface entirely free of
/// delegate plumbing rules out any interaction between Apple's
/// Observation framework and the WatchConnectivity callback queue.
@MainActor
@Observable
final class AutomationStateStore {
    static let shared = AutomationStateStore()

    /// Latest snapshot received from iOS, or `nil` if none has arrived
    /// yet (unpaired, app uninstalled on iPhone, or first launch).
    var snapshot: AutomationWatchSnapshot?

    private init() {}
}
