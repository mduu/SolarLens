import SwiftUI

struct BatteryForecastView: View {
    let batteryForecast: BatteryForecast?

    private let positionalFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated  // e.g., "01:01:05" or "01:05"
        formatter.allowedUnits = [.hour, .minute]
        formatter.zeroFormattingBehavior = .pad
        formatter.collapsesLargestUnit = true  // If hours are 0, it collapses to minutes and seconds
        return formatter
    }()

    private let maxDuration: TimeInterval = 24 * 3600  // 24 hours

    var body: some View {
        if let forecast = batteryForecast,
           (forecast.isDischarging && (forecast.durationUntilDischarged ?? 0) <= maxDuration)
            || (forecast.isCharging && (forecast.durationUntilFullyCharged ?? 0) <= maxDuration)
        {
            HStack {

                if forecast.isDischarging, (forecast.durationUntilDischarged ?? 0) <= maxDuration {
                    Image(systemName: "battery.0percent")
                        .foregroundColor(.red)
                        .rotationEffect(.degrees(-90))
                        .offset(x: -4)

                    Text(
                        "Empty in \(positionalFormatter.string(from: forecast.durationUntilDischarged!) ?? "") at \(forecast.timeWhenDischarged!.formatted(date: .omitted, time: .shortened))"
                    )
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .frame(minHeight: 40)
                    .padding(.leading, -6)
                }  // :if

                if forecast.isCharging, (forecast.durationUntilFullyCharged ?? 0) <= maxDuration {

                    Image(systemName: "battery.100percent")
                        .foregroundColor(.green)
                        .rotationEffect(.degrees(-90))
                        .offset(x: -6)

                    Text(
                        "Full in \(positionalFormatter.string(from: forecast.durationUntilFullyCharged!) ?? "") at \(forecast.timeWhenFullyCharged!.formatted(date: .omitted, time: .shortened))"
                    )
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .frame(minHeight: 40)
                    .padding(.leading, -10)
                }  // :if
                
                Spacer()

            }  // :HStack

        }
    }
}

#Preview("Charging") {
    BatteryForecastView(
        batteryForecast: BatteryForecast(
            durationUntilFullyCharged: 400,
            timeWhenFullyCharged: Date().addingTimeInterval(3600),
            durationUntilDischarged: nil,
            timeWhenDischarged: nil
        )
    )
}

#Preview("Dicharging") {
    BatteryForecastView(
        batteryForecast: BatteryForecast(
            durationUntilFullyCharged: nil,
            timeWhenFullyCharged: nil,
            durationUntilDischarged: 400,
            timeWhenDischarged: Date().addingTimeInterval(3600),
        )
    )
}
