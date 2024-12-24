import Foundation

extension Date {
    func convertFromUTCToLocalTime() -> Date {
        let localTimeZone = TimeZone.current
        let sourceTimeZone = TimeZone(abbreviation: "UTC")!

        let localOffset = localTimeZone.secondsFromGMT(for: self)
        let utcOffset = sourceTimeZone.secondsFromGMT(for: self)

        let intervalDifference = localOffset - utcOffset

        return Date(timeInterval: TimeInterval(intervalDifference), since: self)
    }

    static func todayStartOfDay() -> Date {
        return Calendar.current.startOfDay(for: Date())
    }

    static func todayEndOfDay() -> Date {
        return Calendar.current.date(
            bySettingHour: 23, minute: 59, second: 59, of: Date())!
    }

}
