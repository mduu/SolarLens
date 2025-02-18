import SwiftUI

struct SolarBoubleView: View {
    var solarInKwh: Double
    
    var body: some View {
        CircularInstrument(
            borderColor: Color.accentColor,
            label: "Solar Production",
            value: String(format: "%.1f kW", solarInKwh)
        ) {
            Image(systemName: "sun.max")
                .foregroundColor(.black)
        }
    }
}

#Preview {
    SolarBoubleView(solarInKwh: 5.4)
}
