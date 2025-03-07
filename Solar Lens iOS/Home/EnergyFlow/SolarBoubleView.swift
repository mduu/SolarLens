import SwiftUI

struct SolarBoubleView: View {
    var solarInKwh: Double
    
    var body: some View {
        CircularInstrument(
            borderColor: solarInKwh != 0 ? .accentColor : .gray,
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
