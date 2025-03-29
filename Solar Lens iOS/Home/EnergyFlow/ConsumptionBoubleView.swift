import SwiftUI

struct ConsumptionBoubleView: View {
    var currentConsumptionInKwh: Double
    var todayConsumptionInWh: Double?

    var body: some View {

        CircularInstrument(
            borderColor: currentConsumptionInKwh != 0 ? .teal : .gray,
            label: "Consumption",
            value: String(
                format: "%.1f kW", currentConsumptionInKwh)
        ) {
            VStack {
                if todayConsumptionInWh != nil {
                    TodayValue(valueInWh: todayConsumptionInWh!)
                }

                Image(systemName: "house")
                    .foregroundColor(.black)
                    .padding(.top, 1)
            }
        }

    }
}

#Preview("No autarchy") {
    ConsumptionBoubleView(
        currentConsumptionInKwh: 4.5,
        todayConsumptionInWh: 34595
    )
    .frame(width: 150, height: 150)
}
