import Foundation

struct ForecastItemV1Response : Codable {
    var timestamp: TimeInterval
    var expected: Double = 0
    var min: Double = 0
    var max: Double = 0
}
