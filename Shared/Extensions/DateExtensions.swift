internal import Foundation

extension Date {

    func convertLocalUiToUtc() -> Date {
        let timezoneOffset = TimeInterval(TimeZone.current.secondsFromGMT())
        return self.addingTimeInterval(-timezoneOffset)
    }

    func convertToLocalTime() -> Date {
        let timeZoneOffset = TimeInterval(TimeZone.current.secondsFromGMT())
        return self.addingTimeInterval(timeZoneOffset)
    }

    func isOlderThen(secondsSinceNow seconds: Int) -> Bool {
        self.addingTimeInterval(TimeInterval(seconds)) <= Date()
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

extension Date? {
    func isOlderThen(secondsSinceNow seconds: Int) -> Bool {
        guard let self else { return true }
        return self.isOlderThen(secondsSinceNow: seconds)
    }
}
