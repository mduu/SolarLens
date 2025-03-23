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
                Image(systemName: "house")
                    .foregroundColor(.black)
                
                if todayConsumptionInWh != nil {
                    TodayValue(valueInWh: todayConsumptionInWh!)
                        .padding(.top, 6)
                }}
        }
    }
}

#Preview {
    ConsumptionBoubleView(
        currentConsumptionInKwh: 4.5,
        todayConsumptionInWh: 34595
    )
        .frame(width: 50, height: 50)
}
