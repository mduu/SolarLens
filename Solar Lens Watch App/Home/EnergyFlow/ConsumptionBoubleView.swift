import SwiftUI

struct ConsumptionBoubleView: View {
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
                        format: "Total household consumption is %0 kilo-watt",
                        currentOverallConsumption!.formatWattsAsKiloWatts()
                    ) : "No household consumption"
            )
            .modifier(
                ConditionalFrame(
                    widthSmallWatch: 40,
                    heightSmallWatch: 40,
                    widthLargeWatch: 46,
                    heightLargeWatch: 46
                )
            )
            .padding(3)
            .background(Color.gray.opacity(0.3))
            .cornerRadius(22)

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
    ConsumptionBoubleView(
        currentOverallConsumption: 1230,
        isAnyCarCharging: false
    )
    .frame(width: 50, height: 50)
}

#Preview("Charing") {
    ConsumptionBoubleView(
        currentOverallConsumption: 1230,
        isAnyCarCharging: true
    )
    .frame(width: 50, height: 50)
}
