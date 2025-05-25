import Foundation

struct BatteryForecast : Sendable {
    let durationUntilFullyCharged: TimeInterval?
    let timeWhenFullyCharged: Date?
    let durationUntilDischarged: TimeInterval?
    let timeWhenDischarged: Date?
}
