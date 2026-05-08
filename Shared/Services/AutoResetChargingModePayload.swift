public import Foundation

/// Snapshot of the Auto-reset Charging Mode automation state, sized for
/// the Live Activity content budget.
///
/// Fields are limited to what the Lock Screen card and Dynamic Island
/// actually need to render. The countdown is rendered natively by SwiftUI's
/// `Text(timerInterval:)` from the `resetAt` date, so this payload doesn't
/// have to be re-pushed every second to keep the timer ticking.
public struct AutoResetChargingModePayload: Codable, Hashable {
    /// Localised name of the mode the wallbox is currently set to (the one
    /// the user picked as the active mode at start time).
    public var activeModeTitle: String
    /// Localised name of the mode the wallbox will be switched to once
    /// `resetAt` is reached (or when the user cancels).
    public var afterResetModeTitle: String
    /// Absolute date when the reset fires. Drives the LA's native
    /// countdown via `Text(timerInterval:)`.
    public var resetAt: Date

    public init(
        activeModeTitle: String,
        afterResetModeTitle: String,
        resetAt: Date
    ) {
        self.activeModeTitle = activeModeTitle
        self.afterResetModeTitle = afterResetModeTitle
        self.resetAt = resetAt
    }
}
