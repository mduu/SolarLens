import Charts
import SwiftUI

struct SolarForecastView: View {
    var solarProductionMax: Double
    var todaySolarProduction: Double?
    var forecastToday: ForecastItem?
    var forecastTomorrow: ForecastItem?
    var forecastDayAfterTomorrow: ForecastItem?

    @State private var solarWeather = SolarWeatherService.shared

    private var forecasts: [(label: String, value: Double)] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        let today = Date()
        return [
            (formatter.string(from: today), forecastToday?.expected ?? 0),
            (formatter.string(from: Calendar.current.date(byAdding: .day, value: 1, to: today)!), forecastTomorrow?.expected ?? 0),
            (formatter.string(from: Calendar.current.date(byAdding: .day, value: 2, to: today)!), forecastDayAfterTomorrow?.expected ?? 0),
        ]
    }

    private var maxValue: Double {
        max(forecasts.map(\.value).max() ?? 1, 1)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "chart.bar.fill")
                    .font(.caption2)
                    .foregroundStyle(.accent)
                Text("Forecast")
                    .font(.caption)
                    .foregroundStyle(.primary)
            }

            // Mini bar chart
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(forecasts.enumerated()), id: \.offset) { _, item in
                    VStack(spacing: 4) {
                        Text(String(format: "%.0f", item.value))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.accent.opacity(0.7), .accent.opacity(0.3)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: max(barHeight(for: item.value), 4))

                        Text(item.label)
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            SunTimesView(sunrise: solarWeather.sunrise, sunset: solarWeather.sunset)
        }
        .cardStyle()
        .onAppear {
            AppStoreReviewManager.shared.setSolarDetailsShownAtLeastOnce()
            Task {
                await solarWeather.fetchSunTimes()
            }
        }
    }

    private func barHeight(for value: Double) -> CGFloat {
        let maxBarHeight: CGFloat = 36
        return CGFloat(value / maxValue) * maxBarHeight
    }
}

#Preview {
    SolarForecastView(
        solarProductionMax: 11000,
        todaySolarProduction: 8910,
        forecastToday: ForecastItem(min: 5, max: 10, expected: 8),
        forecastTomorrow: ForecastItem(min: 2, max: 5, expected: 3),
        forecastDayAfterTomorrow: ForecastItem(min: 15, max: 25, expected: 20)
    )
    .padding()
}
