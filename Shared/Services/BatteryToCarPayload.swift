public import Foundation

/// Snapshot of the Battery → Car automation state, sized for the Live
/// Activity content budget. Fields are limited to what the Lock Screen card
/// and Dynamic Island actually render — not a mirror of the full
/// `AutomationBatteryToCarState`.
public struct BatteryToCarPayload: Codable, Hashable {
    public var batterySoc: Int
    public var floorSoc: Int
    public var stationPowerW: Int
    public var currentAmps: Int
    public var kWhTransferred: Double
    /// When the linear forecast says the battery will reach the soft
    /// floor. `nil` when the forecast is unavailable (no telemetry yet,
    /// idle/charging instead of discharging, etc.). LA renders this as
    /// a native `Text(timerInterval:)` countdown so the ETA ticks down
    /// without the runner being involved.
    public var forecastedFloorAt: Date?
    /// Latest house-battery charge rate in watts. Positive = charging,
    /// negative = discharging, near-zero = idle. Drives the "Trend"
    /// metric on the LA card, mirroring the in-app running card.
    /// `nil` before the first telemetry tick.
    public var lastBatteryChargeRateW: Int?

    public init(
        batterySoc: Int,
        floorSoc: Int,
        stationPowerW: Int,
        currentAmps: Int,
        kWhTransferred: Double,
        forecastedFloorAt: Date?,
        lastBatteryChargeRateW: Int? = nil
    ) {
        self.batterySoc = batterySoc
        self.floorSoc = floorSoc
        self.stationPowerW = stationPowerW
        self.currentAmps = currentAmps
        self.kWhTransferred = kWhTransferred
        self.forecastedFloorAt = forecastedFloorAt
        self.lastBatteryChargeRateW = lastBatteryChargeRateW
    }
}
