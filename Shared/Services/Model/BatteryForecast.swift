internal import Foundation

struct BatteryForecast : Sendable {
    let durationUntilFullyCharged: TimeInterval?
    let timeWhenFullyCharged: Date?
    let durationUntilDischarged: TimeInterval?
    let timeWhenDischarged: Date?
    
    var isCharging: Bool {
        durationUntilFullyCharged != nil && timeWhenFullyCharged != nil
    }
    
    var isDischarging: Bool {
        durationUntilDischarged != nil && timeWhenDischarged != nil
    }

    /// Whether the forecast has data worth showing (within 24 hours).
    var hasVisibleForecast: Bool {
        let maxDuration: TimeInterval = 24 * 3600
        if isCharging, let d = durationUntilFullyCharged, d <= maxDuration { return true }
        if isDischarging, let d = durationUntilDischarged, d <= maxDuration { return true }
        return false
    }
}
