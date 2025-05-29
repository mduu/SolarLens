import Foundation

class RestDateHelper {

    static func string(from date: Date) -> String {
        let dateFormatter = getDateFormatterWithoutTimezone()
        return dateFormatter.string(from: date)
    }

    static func date(from string: String?) -> Date? {
        guard let string else { return nil }
        let dateFormatter = getDateFormatterWithZulu()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"

        let result = dateFormatter.date(from: string)
        return result
    }
    
    private static func getDateFormatterWithZulu() -> DateFormatter {
        let dateFormatter = getDateFormatterWithoutTimezone()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return dateFormatter
    }

    private static func getDateFormatterWithoutTimezone() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // Ensures 24h format
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"

        return dateFormatter
    }
}
