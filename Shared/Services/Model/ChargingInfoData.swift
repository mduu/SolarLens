import SwiftUI

@Observable
class CharingInfoData {
    var totalCharedToday: Double? = nil
    var currentCharging: Int? = nil
    /// Today's charged energy per charging-station sensor id, in Wh
    /// (same unit as `totalCharedToday`). Empty when no per-station data
    /// could be fetched. Used by the iOS charging sheet to show how much
    /// each station has charged today.
    var chargedTodayPerSensorId: [String: Double] = [:]

    init(
        totalCharedToday: Double?,
        currentCharging: Int?,
        chargedTodayPerSensorId: [String: Double] = [:]
    ) {
        self.totalCharedToday = totalCharedToday
        self.currentCharging = currentCharging
        self.chargedTodayPerSensorId = chargedTodayPerSensorId
    }
}
