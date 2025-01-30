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
                    ? String(
                        format: "%.1f",
                        Double(currentOverallConsumption!) / 1000
                    ) : "-",
                smallText: unitText
            )

            HStack(alignment: VerticalAlignment.bottom) {
                Image(systemName: "house")
                if isAnyCarCharging {
                    Image(systemName: "car.side")
                        .symbolEffect(
                            .pulse.wholeSymbol, options: .repeat(.continuous))
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
