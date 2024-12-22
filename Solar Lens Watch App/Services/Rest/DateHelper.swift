import Foundation

class RestDateHelper {

    static func string(from date: Date) -> String {
        let dateFormatter = getDateFormatter()
        return dateFormatter.string(from: date)
    }

    static func date(from string: String?) -> Date? {
        guard let string else { return nil }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        dateFormatter.timeZone = TimeZone.current

        let result = dateFormatter.date(from: string)
        return result
    }

    private static func getDateFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        return dateFormatter
    }
}
