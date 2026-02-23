import CoreLocation
internal import Foundation
import SwiftUI

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
            print("No location available for sun times")
            return
        }

        let times = Self.calculateSunTimes(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            date: Date()
        )

        await MainActor.run {
            self.sunrise = times.sunrise
            self.sunset = times.sunset
        }
    }

    // NOAA solar calculator based on Jean Meeus' "Astronomical Algorithms"
    // Reference: https://gml.noaa.gov/grad/solcalc/solareqns.PDF
    static func calculateSunTimes(
        latitude: Double,
        longitude: Double,
        date: Date
    ) -> (sunrise: Date?, sunset: Date?) {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        // Julian Day Number
        let jdn = julianDayNumber(year: year, month: month, day: day)

        // Julian Century from J2000.0
        let T = (Double(jdn) - 2451545.0) / 36525.0

        // Geometric mean longitude of the Sun (degrees)
        let L0 = (280.46646 + T * (36000.76983 + 0.0003032 * T))
            .truncatingRemainder(dividingBy: 360.0)

        // Mean anomaly of the Sun (degrees)
        let M = (357.52911 + T * (35999.05029 - 0.0001537 * T))
            .truncatingRemainder(dividingBy: 360.0)
        let Mrad = M * .pi / 180.0

        // Equation of center (degrees)
        let C = sin(Mrad) * (1.9146 - T * (0.004817 + 0.000014 * T))
            + sin(2.0 * Mrad) * (0.019993 - 0.000101 * T)
            + sin(3.0 * Mrad) * 0.000289

        // Sun's true longitude (degrees)
        let sunLon = L0 + C

        // Sun's apparent longitude (degrees)
        let omega = 125.04 - 1934.136 * T
        let omegaRad = omega * .pi / 180.0
        let lambda = sunLon - 0.00569 - 0.00478 * sin(omegaRad)
        let lambdaRad = lambda * .pi / 180.0

        // Mean obliquity of the ecliptic (degrees)
        let epsilon0 = 23.0 + (26.0 + (21.448 - T * (46.815 + T * (0.00059 - T * 0.001813))) / 60.0) / 60.0

        // Corrected obliquity (degrees)
        let epsilon = epsilon0 + 0.00256 * cos(omegaRad)
        let epsilonRad = epsilon * .pi / 180.0

        // Sun's declination (radians)
        let sinDec = sin(epsilonRad) * sin(lambdaRad)
        let declination = asin(sinDec)

        // Equation of Time (minutes)
        let y = tan(epsilonRad / 2.0) * tan(epsilonRad / 2.0)
        let L0rad = L0 * .pi / 180.0
        let eqTime = 4.0 * (180.0 / .pi) * (
            y * sin(2.0 * L0rad)
            - 2.0 * 0.016709 * sin(Mrad)
            + 4.0 * 0.016709 * y * sin(Mrad) * cos(2.0 * L0rad)
            - 0.5 * y * y * sin(4.0 * L0rad)
            - 1.25 * 0.016709 * 0.016709 * sin(2.0 * Mrad)
        )

        // Hour angle for sunrise/sunset (degrees)
        // Using standard refraction correction of 0.833°
        let latRad = latitude * .pi / 180.0
        let zenith = 90.833 * .pi / 180.0 // 90° 50' = official sunrise/sunset

        let cosHA = (cos(zenith) / (cos(latRad) * cos(declination)))
            - tan(latRad) * tan(declination)

        // No sunrise/sunset (polar day or polar night)
        if cosHA < -1.0 || cosHA > 1.0 {
            return (nil, nil)
        }

        let HA = acos(cosHA) * 180.0 / .pi // in degrees

        // Solar noon in minutes from midnight UTC
        let solarNoon = 720.0 - 4.0 * longitude - eqTime

        // Sunrise and sunset in minutes from midnight UTC
        let sunriseMinutes = solarNoon - HA * 4.0
        let sunsetMinutes = solarNoon + HA * 4.0

        // Convert to Date objects using today's midnight UTC as reference
        let startOfDayUTC = utcMidnight(year: year, month: month, day: day)

        guard let startUTC = startOfDayUTC else {
            return (nil, nil)
        }

        let sunriseDate = startUTC.addingTimeInterval(sunriseMinutes * 60.0)
        let sunsetDate = startUTC.addingTimeInterval(sunsetMinutes * 60.0)

        return (sunriseDate, sunsetDate)
    }

    // Julian Day Number for a calendar date (at noon UT)
    private static func julianDayNumber(year: Int, month: Int, day: Int) -> Int {
        var y = year
        var m = month
        if m <= 2 {
            y -= 1
            m += 12
        }
        let A = y / 100
        let B = 2 - A + A / 4
        return Int(365.25 * Double(y + 4716)) + Int(30.6001 * Double(m + 1)) + day + B - 1525
    }

    // Midnight UTC for a given calendar date
    private static func utcMidnight(year: Int, month: Int, day: Int) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 0
        components.minute = 0
        components.second = 0
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        return utcCalendar.date(from: components)
    }
}
