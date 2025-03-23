import SwiftUI

struct ForecastListView: View {
    var maxProduction: Double?
    var forecastToday: ForecastItem?
    var forecastTomorrow: ForecastItem?
    var forecastDayAfterTomorrow: ForecastItem?
    var small: Bool = true

    var body: some View {
        HStack {
            ForecastItemView(
                date: Calendar.current.startOfDay(for: Date()),
                maxProduction: maxProduction ?? 0,
                forecasts: [
                    forecastToday,
                    forecastTomorrow,
                    forecastDayAfterTomorrow,
                ],
                forecast: forecastToday,
                small: small
            )

            ForecastItemView(
                date: Calendar.current.date(
                    byAdding: .day, value: 1, to: Date()
                ),
                maxProduction: maxProduction ?? 0,
                forecasts: [
                    forecastToday,
                    forecastTomorrow,
                    forecastDayAfterTomorrow,
                ],
                forecast: forecastTomorrow,
                small: small
            )

            ForecastItemView(
                date: Calendar.current.date(
                    byAdding: .day, value: 2, to: Date()
                ),
                maxProduction:
                    maxProduction ?? 0,
                forecasts: [
                    forecastToday,
                    forecastTomorrow,
                    forecastDayAfterTomorrow,
                ],
                forecast: forecastDayAfterTomorrow,
                small: small
            )
        }  // :HStack
    }
}

#Preview {
    ForecastListView(
        maxProduction: 11000,
        forecastToday: ForecastItem(min: 1.0, max: 1.4, expected: 1.2),
        forecastTomorrow: ForecastItem(min: 0.2, max: 0.4, expected: 0.3),
        forecastDayAfterTomorrow: ForecastItem(min: 3.2, max: 3.4, expected: 3.3)
    )
}
