import SwiftUI

struct ThreeDaysForecastView: View {
    var solarDetails: SolarDetailsData?

    var body: some View {
        VStack {
            if solarDetails == nil {
                ContentUnavailableView(
                    "No Data Available",
                    systemImage: "sun.rain",
                    description: Text("Forecast will appear here when data is available.")
                )

            } else {
                VStack {
                    let overallMin = getOverallMin()
                    let overallMax = getOverallMax()

                    DayForecastView(
                        dayForecast: solarDetails?.forecastToday,
                        dayLabel: "Today",
                        overallMinimum: overallMin,
                        overallMaximum: overallMax
                    )

                    DayForecastView(
                        dayForecast: solarDetails?.forecastTomorrow,
                        dayLabel: "Tomorrow",
                        overallMinimum: overallMin,
                        overallMaximum: overallMax
                    )

                    DayForecastView(
                        dayForecast: solarDetails?.forecastDayAfterTomorrow,
                        dayLabel: "After tomorrow",
                        overallMinimum: overallMin,
                        overallMaximum: overallMax
                    )
                }
            }

            Spacer()
        }
    }

    func getOverallMin() -> Double {
        return min(
            solarDetails?.forecastToday?.min ?? 0,
            solarDetails?.forecastTomorrow?.min ?? 0,
            solarDetails?.forecastDayAfterTomorrow?.min ?? 0
        )
    }

    func getOverallMax() -> Double {
        return max(
            solarDetails?.forecastToday?.max ?? 0,
            solarDetails?.forecastTomorrow?.max ?? 0,
            solarDetails?.forecastDayAfterTomorrow?.max ?? 0
        )
    }
}

#Preview {
    ThreeDaysForecastView(
        solarDetails: .fake()
    )
}
