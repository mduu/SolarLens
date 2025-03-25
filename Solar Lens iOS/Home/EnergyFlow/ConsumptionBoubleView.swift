import SwiftUI

struct ConsumptionBoubleView: View {
    var currentConsumptionInKwh: Double
    var todayConsumptionInWh: Double?
    var todayAutarchyDegree: Double?

    var body: some View {
        let percent = Text("\(Int(todayAutarchyDegree ?? 0))%")
            .fontWeight(.bold)

        ZStack {

            CircularInstrument(
                borderColor: currentConsumptionInKwh != 0 ? .teal : .gray,
                label: "Consumption",
                value: String(
                    format: "%.1f kW", currentConsumptionInKwh)
            ) {
                VStack {

                    Image(systemName: "house")
                        .foregroundColor(.black)

                    if todayConsumptionInWh != nil {
                        TodayValue(valueInWh: todayConsumptionInWh!)
                            .padding(.top, 6)
                    }
                    
                    Text("Autarchy: \(percent)")
                }
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

#Preview("With autarchy") {
    ConsumptionBoubleView(
        currentConsumptionInKwh: 4.5,
        todayConsumptionInWh: 34595,
        todayAutarchyDegree: 88
    )
    .frame(width: 150, height: 150)
}
