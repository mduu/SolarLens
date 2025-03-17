import SwiftUI

struct ConsumptionBoubleView: View {
    var totalConsumptionInKwh: Double
    
    var body: some View {
        CircularInstrument(
            borderColor: totalConsumptionInKwh != 0 ? .teal : .gray,
            label: "Consumption",
            value: String(
                format: "%.1f kW", totalConsumptionInKwh)
        ) {
            Image(systemName: "house")
                .foregroundColor(.black)
        }
    }
}

#Preview {
    ConsumptionBoubleView(totalConsumptionInKwh: 4.5)
        .frame(width: 50, height: 50)
}
