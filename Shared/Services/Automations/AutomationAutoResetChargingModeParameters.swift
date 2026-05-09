internal import Foundation

struct AutomationAutoResetChargingModeParameters: Codable, Sendable {
    var chargingDeviceId: String = ""
    /// Mode the wallbox is set to immediately when the user taps Start.
    var activeChargingMode: ChargingMode = .alwaysCharge
    /// Mode the wallbox is set to once `resetAt` is reached (or on cancel).
    var afterResetChargingMode: ChargingMode = .withSolarPower
    /// Absolute date when the post-reset mode is applied.
    var resetAt: Date = Date().addingTimeInterval(60 * 60)

    init() {}

    init(
        chargingDeviceId: String,
        activeChargingMode: ChargingMode,
        afterResetChargingMode: ChargingMode,
        resetAt: Date
    ) {
        self.chargingDeviceId = chargingDeviceId
        self.activeChargingMode = activeChargingMode
        self.afterResetChargingMode = afterResetChargingMode
        self.resetAt = resetAt
    }
}

enum AutomationAutoResetChargingModeStopReason: String, Codable, Sendable {
    case resetCompleted
    case cancelled
}

struct AutomationAutoResetChargingModeState: Codable, Sendable {
    var isStarted: Bool = false
    var startedAt: Date? = nil
    /// Recorded when the active mode was successfully applied at the very
    /// first tick. `nil` if the API call failed or the run hasn't started
    /// yet.
    var appliedActiveModeAt: Date? = nil
    /// Recorded when the post-reset mode was successfully applied (either
    /// because the reset time fired or the user cancelled).
    var appliedAfterResetModeAt: Date? = nil
    /// Snapshot of the mode that was set as the active mode — useful for
    /// diagnostics if the user reports something unexpected.
    var activeChargingModeAtStart: ChargingMode? = nil
    var stopReason: AutomationAutoResetChargingModeStopReason? = nil

    init() {}
}
