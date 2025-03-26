import SwiftUI

@Observable
class SolarDetailsData {
    var todaySolarProduction: Double?
    var forecastToday: ForecastItem?
    var forecastTomorrow: ForecastItem?
    var forecastDayAfterTomorrow: ForecastItem?

    init(
        todaySolarProduction: Double? = nil,
        forecastToday: ForecastItem? = nil,
        forecastTomorrow: ForecastItem? = nil,
        forecastDayAfterTomorrow: ForecastItem? = nil
    ) {
        self.todaySolarProduction = todaySolarProduction
        self.forecastToday = forecastToday
        self.forecastTomorrow = forecastTomorrow
        self.forecastDayAfterTomorrow = forecastDayAfterTomorrow
    }
}

extension SolarDetailsData {
    static func fake() -> SolarDetailsData {
        .init(
            todaySolarProduction: 18.4,
            forecastToday: .init(min: 3, max: 6, expected: 5.6),
            forecastTomorrow: .init(min: 10.3, max: 15.4, expected: 12.4),
            forecastDayAfterTomorrow: .init(
                min: 15.4, max: 22.4, expected: 20.1)
        )
    }
}

struct ForecastItem {
    var min: Double
    var max: Double
    var expected: Double

    var stringRange: String {
        let minStr = String(format: "%.0f", min)
        let maxStr = String(format: "%.0f", max)

        if minStr == maxStr {
            return minStr
        }

        return "\(minStr)-\(maxStr)"
    }
}
