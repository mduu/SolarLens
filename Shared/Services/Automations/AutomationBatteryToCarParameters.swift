internal import Foundation

struct AutomationBatteryToCarParameters: Codable, Sendable {
    var chargingDeviceId: String = ""
    var minBatteryLevel: Int = 30
    var fallbackChargingMode: ChargingMode = .withSolarPower
    var phases: WallboxPhases = .three

    init() {}

    init(
        chargingDeviceId: String,
        minBatteryLevel: Int,
        fallbackChargingMode: ChargingMode,
        phases: WallboxPhases = .three
    ) {
        self.chargingDeviceId = chargingDeviceId
        self.minBatteryLevel = minBatteryLevel
        self.fallbackChargingMode = fallbackChargingMode
        self.phases = phases
    }
}

enum AutomationBatteryToCarStopReason: String, Codable, Sendable {
    case softFloorReached
    case capped
    case cancelled
}

struct AutomationBatteryToCarState: Codable, Sendable {
    var isStarted: Bool = false
    var startSoc: Int = 0
    var endSoc: Int? = nil
    var lastBatteryPercentage: Int? = nil
    var previousChargingMode: ChargingMode? = nil
    /// Default 6 A — minimum protocol-allowed amperage. Kept as a hardcoded
    /// constant so this Codable model has no dependency on the iOS-only
    /// `PowerToAmps` helper (which holds the same value as `minAmps`).
    var currentAmps: Int = 6
    var kWhTransferred: Double = 0
    var lastTickAt: Date? = nil
    var gridImportStreak: Int = 0
    var smoothedTickIntervalMinutes: Double = 1.0
    var stopReason: AutomationBatteryToCarStopReason? = nil
    /// Most recent linear forecast for when the battery hits the soft
    /// floor. Refreshed each tick. `nil` if the forecast is
    /// unavailable (idle/charging battery, no telemetry yet).
    var forecastedFloorAt: Date? = nil
    /// Most recent house-battery charge rate (W). Positive = charging,
    /// negative = discharging, near-zero = idle. Used by the UI to
    /// explain why a forecast isn't available.
    var lastBatteryChargeRate: Int? = nil

    init() {}

    init(
        isStarted: Bool,
        startSoc: Int,
        lastBatteryPercentage: Int?,
        previousChargingMode: ChargingMode,
        currentAmps: Int,
        kWhTransferred: Double,
        lastTickAt: Date?,
        gridImportStreak: Int,
        smoothedTickIntervalMinutes: Double,
        stopReason: AutomationBatteryToCarStopReason?
    ) {
        self.isStarted = isStarted
        self.startSoc = startSoc
        self.lastBatteryPercentage = lastBatteryPercentage
        self.previousChargingMode = previousChargingMode
        self.currentAmps = currentAmps
        self.kWhTransferred = kWhTransferred
        self.lastTickAt = lastTickAt
        self.gridImportStreak = gridImportStreak
        self.smoothedTickIntervalMinutes = smoothedTickIntervalMinutes
        self.stopReason = stopReason
    }
}
