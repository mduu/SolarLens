import CoreLocation
internal import Foundation
import SwiftUI
import WeatherKit

@Observable
class SolarWeatherService {
    static let shared = SolarWeatherService()

    var sunrise: Date?
    var sunset: Date?

    private let locationManager = LocationManager()

    func fetchSunTimes() async {
        if (sunrise != nil && Calendar.current.startOfDay(for: sunrise!) == Date.todayStartOfDay())
            && (sunset != nil && Calendar.current.startOfDay(for: sunset!) == Date.todayStartOfDay())
        {
            return
        }

        guard let location = await locationManager.requestLocation() else {
            print("No location available for weather")
            return
        }

        do {
            let weather = try await WeatherService.shared.weather(for: location)

            // Find today's forecast
            if let today = weather.dailyForecast.first(where: { Calendar.current.isDateInToday($0.date) }) {
                await MainActor.run {
                    self.sunrise = today.sun.sunrise
                    self.sunset = today.sun.sunset
                }
            }
        } catch {
            print("Weather fetch failed: \(error)")
        }
    }
}
