import SwiftUI

struct ConsumptionBoubleView: View {
    var gridInKwh: Double
    
    var body: some View {
        CircularInstrument(
            borderColor: Color.teal,
            label: "Consumption",
            value: String(
                format: "%.1f kW", gridInKwh)
        ) {
            Image(systemName: "house")
                .foregroundColor(.black)
        }
    }
}

#Preview {
    ConsumptionBoubleView(gridInKwh: 4.5)
        .frame(width: 150, height: 150)
}
