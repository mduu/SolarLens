import SwiftUI
import WidgetKit

struct ForecastItemView: View {
    var date: Date?
    var maxProduction: Double
    var forecasts: [ForecastItem?]
    var forecast: ForecastItem?
    var small: Bool?
    var intense: Bool = false

    @Environment(\.colorScheme) var colorScheme

    var shortDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }

    var body: some View {
        let isSmall = small ?? false

        ZStack {

            GeometryReader { geometry in
                ZStack {

                    RoundedRectangle(cornerRadius: 5)
                        .fill(getColor().opacity(intense ? 0.2 : 0.1))
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height
                        )
                        .widgetAccentable()

                    RoundedRectangle(cornerRadius: 5)
                        .fill(
                            small ?? false
                                ? LinearGradient(
                                    gradient: Gradient(colors: [
                                        getColor().opacity(intense ? 0.2 : 0.1)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                : LinearGradient(
                                    gradient: Gradient(colors: [
                                        getColor().opacity(
                                            intense ? 0.30 : 0.15),
                                        getColor().opacity(
                                            intense ? 0.05 : 0.01),
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                        )
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height * getPercentage()
                        )
                        .position(
                            x: geometry.size.width / 2,
                            y: geometry.size.height * (1 - getPercentage() / 2)
                        )  // Position relative to parent's height
                        .widgetAccentable()
                }
            }

            VStack {
                if date != nil {

                    Text(
                        date!,
                        formatter: shortDateFormatter
                    )
                    #if os(watchOS)
                        .font(isSmall ? .system(size: 10) : .body)
                    #else
                        .font(.system(size: 10))
                    #endif
                    .widgetAccentable()

                    Text("\(forecast?.stringRange ?? "")")
                        .foregroundColor(
                            colorScheme == .dark
                                ? getColor()
                                : .primary
                        )
                        #if os(watchOS)
                            .font(.headline)
                        #else
                            .font(isSmall ? .system(size: 11) : .caption2)
                        #endif

                    if !isSmall {
                        Text("kWh")
                            .font(.system(size: 10))
                    }

                }  // :if
            }  // :VStack
            .padding(4)

        }  // :ZStack

    }

    private func getColor() -> Color {
        return small ?? false ? .accent : .yellow
    }

    private func getPercentage() -> Double {
        let maxForecast = forecasts.map({ $0?.max ?? 0 }).max() ?? 0
        return min((forecast?.expected ?? 0) / maxForecast, 1.0)
    }
}

#Preview("Normal") {
    ForecastItemView(
        date: Date(),
        maxProduction: 11000,
        forecasts: [
            ForecastItem(min: 1.0, max: 1.4, expected: 1.2),
            ForecastItem(min: 0.2, max: 0.4, expected: 0.3),
            ForecastItem(min: 3.2, max: 3.4, expected: 3.3),
        ],
        forecast: ForecastItem(min: 1.2, max: 1.4, expected: 1.3),
        small: false
    )
}

#Preview("Small") {
    ForecastItemView(
        date: Date(),
        maxProduction: 11000,
        forecasts: [
            ForecastItem(min: 1.0, max: 1.4, expected: 1.2),
            ForecastItem(min: 0.2, max: 0.4, expected: 0.3),
            ForecastItem(min: 3.2, max: 3.4, expected: 3.3),
        ],
        forecast: ForecastItem(min: 11, max: 30.4, expected: 1.3),
        small: true
    )
    .frame(maxWidth: 30, maxHeight: 60)
}
