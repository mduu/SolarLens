import SwiftUI

struct SolarBoubleView: View {
    var currentSolarProductionInKwh: Double
    var todaySolarProductionInWh: Double?

    var body: some View {
        CircularInstrument(
            borderColor: currentSolarProductionInKwh != 0
                ? .accentColor : .gray,
            label: "Solar Production",
            value: String(format: "%.1f kW", currentSolarProductionInKwh)
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
    SolarBoubleView(
        currentSolarProductionInKwh: 5.4,
        todaySolarProductionInWh: 15500
    )
    .frame(width: 150, height: 150)
}
