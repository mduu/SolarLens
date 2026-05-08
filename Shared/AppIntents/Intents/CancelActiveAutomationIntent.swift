#if canImport(AppIntents) && canImport(ActivityKit)
public import AppIntents
internal import Foundation

/// `LiveActivityIntent` fired by the Cancel button on the Lock Screen card
/// and Dynamic Island expanded view.
///
/// The body delegates to a runtime-registered closure so this file
/// compiles cleanly in both the iOS app target (where the closure is
/// registered against `AutomationManager`) and the widget extension target
/// (where the closure is `nil` — the intent type just needs to be
/// discoverable for ActivityKit's button binding).
///
/// ActivityKit launches the **app** to perform the intent, so the closure
/// always runs in the app's process where `AutomationManager` lives.
public struct CancelActiveAutomationIntent: LiveActivityIntent {
    public static let title: LocalizedStringResource = "Cancel automation"

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult {
        LiveActivityCancelHandler.shared?()
        return .result()
    }
}

/// Registry for the actual cancel work. The iOS app sets `shared` on launch;
/// the widget extension never sets it.
@MainActor
public enum LiveActivityCancelHandler {
    public static var shared: (() -> Void)?
}
#endif
