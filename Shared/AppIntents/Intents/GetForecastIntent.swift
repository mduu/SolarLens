import AppIntents

struct GetForecastIntent: AppIntent {
    static var title: LocalizedStringResource = "Get solar forecast"
    static var description: IntentDescription? =
        "Get the solar forecast in kWh"

    @Parameter(
        title: "Which day",
        description: "Select the day to get the forecast for.",
        default: ForecastDay.today
    )
    var forDay: ForecastDay
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Double>
        & ProvidesDialog
    {
        let solarManager = SolarManager.instance()
        guard let solarDetails = try? await solarManager.fetchSolarDetails()
        else {
            throw IntentError.couldNotGetSolarDetails("Could not get solar forecast")
        }
        
        let dayText = getFurecastDayText(forDay: forDay)
        let forecast: ForecastItem? = getFurecast(
            solarDetail: solarDetails,
            forDay: forDay
        )
        
        guard let currentForecast = forecast else {
            throw IntentError.couldNotGetValue("Could not get forecast!")
        }
        
        let dialog = IntentDialog(
            full:
                LocalizedStringResource(
                    "The forecast for \(dayText) is \(currentForecast.stringRange). Expected is \(currentForecast.expected.formatAsKiloWattsHours())"
                ),
            systemImageName: "slider.horizontal.below.sun.max"
        )

        return .result(value: currentForecast.expected, dialog: dialog)
    }
    
    private func getFurecastDayText(forDay: ForecastDay) -> LocalizedStringResource {
        switch forDay {
        case .today:
            return "today"
        case .tomorrow:
            return "tomorrow"
        case .dayAfterTomorrow:
            return "day after tomorrow"
        }
    }
    
    private func getFurecast(solarDetail: SolarDetailsData, forDay: ForecastDay) -> ForecastItem? {
        switch forDay {
        case .today:
            return solarDetail.forecastToday
        case .tomorrow:
            return solarDetail.forecastTomorrow
        case .dayAfterTomorrow:
            return solarDetail.forecastDayAfterTomorrow
        }
    }
}

enum ForecastDay: Int, Codable, CaseIterable, Identifiable, AppEnum {
    case today = 0
    case tomorrow = 1
    case dayAfterTomorrow = 2

    var id: Int { rawValue }

    static var typeDisplayRepresentation: TypeDisplayRepresentation =
        "Forecast day"

    static var caseDisplayRepresentations:
        [ForecastDay: DisplayRepresentation] = [
            .today: .init(stringLiteral: "Today"),
            .tomorrow: .init(stringLiteral: "Tomorrow"),
            .dayAfterTomorrow: .init(stringLiteral: "Day after tomorrow"),
        ]
}
