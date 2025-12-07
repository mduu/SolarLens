internal import Foundation

struct ForecastV3Response: Codable {
    var data: [ForecastItemV3Response] = []
}

struct ForecastItemV3Response: Codable {
    var t: String?
    var pW: Double = 0
    var pWmin: Double = 0
    var pWmax: Double = 0

    var timeStamp: Date? { RestDateHelper.date(from: t) }

}
