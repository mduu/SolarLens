import Foundation

extension Date {

    func convertLocalUiToUtc() -> Date {
        let timezoneOffset = TimeInterval(TimeZone.current.secondsFromGMT())
        return self.addingTimeInterval(-timezoneOffset)
    }

    func convertToLocalTime() -> Date {
        let timeZoneOffset = TimeInterval(TimeZone.current.secondsFromGMT())
        return self.addingTimeInterval(timeZoneOffset)
    }

    static func todayStartOfDay() -> Date {
        return Calendar.current.startOfDay(for: Date())
    }

    static func todayEndOfDay() -> Date {
        return Calendar.current.date(
            bySettingHour: 23,
            minute: 59,
            second: 59,
            of: Date()
        )!
    }

}
