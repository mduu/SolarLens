import SwiftUI

struct SolarBoubleView: View {
    var currentSolarProductionInKwh: Double
    var todaySolarProductionInWh: Double?
    var useGlow: Bool

    var body: some View {
        CircularInstrument(
            borderColor: currentSolarProductionInKwh != 0
                ? .accentColor : .gray,
            label: "Production",
            value: String(format: "%.1f kW", currentSolarProductionInKwh),
            useGlowEffect: useGlow
        ) {
            VStack {
                TodayValue(valueInWh: todaySolarProductionInWh ?? 0)
                
                Image(systemName: "sun.max")
                    .foregroundColor(.black)
            }
        }
    }
}

#Preview("Default") {
    VStack {
        SolarBoubleView(
            currentSolarProductionInKwh: 5.4,
            todaySolarProductionInWh: 15500,
            useGlow: false
        )
        .frame(width: 150, height: 150)
        
        SolarBoubleView(
            currentSolarProductionInKwh: 5.4,
            todaySolarProductionInWh: 15500,
            useGlow: true
        )
        .frame(width: 150, height: 150)
    }
}
