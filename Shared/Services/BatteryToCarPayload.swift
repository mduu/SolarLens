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

    public init(
        batterySoc: Int,
        floorSoc: Int,
        stationPowerW: Int,
        currentAmps: Int,
        kWhTransferred: Double
    ) {
        self.batterySoc = batterySoc
        self.floorSoc = floorSoc
        self.stationPowerW = stationPowerW
        self.currentAmps = currentAmps
        self.kWhTransferred = kWhTransferred
    }
}
