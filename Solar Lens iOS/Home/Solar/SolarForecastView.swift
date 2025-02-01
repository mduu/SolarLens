import SwiftUI

struct SolarForecastView: View {
    var solarProductionMax: Double
    var todaySolarProduction: Double?
    var forecastToday: ForecastItem?
    var forecastTomorrow: ForecastItem?
    var forecastDayAfterTomorrow: ForecastItem?
    
    @State private var refreshTimer: Timer?

    var body: some View {
        VStack {
            Text("Forecast")
                .font(.headline)
                .foregroundColor(.accent)
            
            HStack {
                ForecastItemView(
                    date: Calendar.current.startOfDay(for: Date()),
                    maxProduction: solarProductionMax,
                    forecasts: [
                        forecastToday,
                        forecastTomorrow,
                        forecastDayAfterTomorrow,
                    ],
                    forecast: forecastToday,
                    small: false,
                    intense: true
                )
                
                ForecastItemView(
                    date: Calendar.current.date(
                            byAdding: .day, value: 1, to: Date()),
                    maxProduction: solarProductionMax,
                    forecasts: [
                        forecastToday,
                        forecastTomorrow,
                        forecastDayAfterTomorrow,
                    ],
                    forecast: forecastTomorrow,
                    small: false,
                    intense: true
                )
                
                ForecastItemView(
                    date: Calendar.current.date(
                            byAdding: .day, value: 2, to: Date()),
                    maxProduction: solarProductionMax,
                    forecasts: [
                        forecastToday,
                        forecastTomorrow,
                        forecastDayAfterTomorrow,
                    ],
                    forecast: forecastDayAfterTomorrow,
                    small: false,
                    intense: true
                )
            } // :HStack
        } // :VStack
        .onAppear {
            AppStoreReviewManager.shared.setSolarDetailsShownAtLeastOnce()
        }  // :onAppear
    }
}

#Preview {
    SolarForecastView(
        solarProductionMax: 11000,
        todaySolarProduction: 8910,
        forecastToday: nil,
        forecastTomorrow: nil,
        forecastDayAfterTomorrow: nil
    )
}
