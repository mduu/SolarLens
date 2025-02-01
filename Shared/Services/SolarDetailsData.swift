import SwiftUI

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
