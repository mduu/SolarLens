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
}
