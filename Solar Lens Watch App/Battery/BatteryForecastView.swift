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

    var body: some View {
        if batteryForecast != nil
            && (batteryForecast?.timeWhenDischarged != nil
                || batteryForecast?.timeWhenFullyCharged != nil)
        {
            HStack {

                if batteryForecast!.isDischarging {
                    Image(systemName: "battery.0percent")
                        .foregroundColor(.red)
                        .rotationEffect(.degrees(-90))

                    VStack(alignment: .leading) {
                        Text(
                            "Empty in \(positionalFormatter.string(from: batteryForecast!.durationUntilDischarged!) ?? "") at \(batteryForecast!.timeWhenDischarged!.formatted(date: .omitted, time: .shortened))"
                        )
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .frame(minHeight: 40)
                    }
                } // :if

                if batteryForecast!.isCharging {

                    Image(systemName: "battery.100percent")
                        .foregroundColor(.green)
                        .rotationEffect(.degrees(-90))

                    Text(
                        "Full in \(positionalFormatter.string(from: batteryForecast!.durationUntilFullyCharged!) ?? "") at \(batteryForecast!.timeWhenFullyCharged!.formatted(date: .omitted, time: .shortened))"
                    )
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .frame(minHeight: 40)

                } // :if
            } // :HStack

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
