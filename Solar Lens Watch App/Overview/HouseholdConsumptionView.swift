import SwiftUI

struct HouseholdConsumptionView: View {
    var currentOverallConsumption: Int?
    var isAnyCarCharging: Bool

    let circleColor: Color = .teal
    let unitText = "kW"

    var body: some View {
        VStack(spacing: 0) {
            CircularInstrument(
                color: circleColor,
                largeText: currentOverallConsumption != nil
                    ? currentOverallConsumption!.formatWattsAsKiloWatts()
                    : "-",
                smallText: unitText
            )
            .accessibilityLabel(
                currentOverallConsumption != nil
                    ? String(
                        format: "Total household consumption is %.1f kilo-watt",
                        currentOverallConsumption!.formatWattsAsKiloWatts()
                    ) : "No household consumption"
            )

            HStack(alignment: VerticalAlignment.bottom) {
                Image(systemName: "house")
                if isAnyCarCharging {
                    Image(systemName: "car.side")
                        .symbolEffect(
                            .pulse.wholeSymbol, options: .repeat(.continuous)
                        )
                        .accessibilityLabel("A car is chariging.")
                }
            }
            .padding(.top, 3)

        }
    }
}

#Preview("No charing") {
    HouseholdConsumptionView(
        currentOverallConsumption: 1230,
        isAnyCarCharging: false
    )
}

#Preview("Charing") {
    HouseholdConsumptionView(
        currentOverallConsumption: 1230,
        isAnyCarCharging: true
    )
}
