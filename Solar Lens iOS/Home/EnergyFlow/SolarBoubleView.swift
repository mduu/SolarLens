import SwiftUI

struct SolarBoubleView: View {
    var solarInKwh: Double
    var todaySolarProductionInWh: Double?
    
    var body: some View {
        CircularInstrument(
            borderColor: solarInKwh != 0 ? .accentColor : .gray,
            label: "Solar Production",
            value: String(format: "%.1f kW", solarInKwh)
        ) {
            VStack {
                Image(systemName: "sun.max")
                    .foregroundColor(.black)
                if todaySolarProductionInWh != nil {
                    TodayValue(valueInWh: todaySolarProductionInWh!)
                        .padding(.top, 6)
                }
            }
        }
    }
}

#Preview {
    SolarBoubleView(solarInKwh: 5.4, todaySolarProductionInWh: 15500)
        .frame(width: 150, height:  150)
}
