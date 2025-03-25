import SwiftUI

struct SolarBoubleView: View {
    var currentSolarProductionInKwh: Double
    var todaySolarProductionInWh: Double?
    var todaySelfConsumptionRate: Double?
    
    var body: some View {
        let percent = Text("\(Int(todaySelfConsumptionRate ?? 0))%")
            .fontWeight(.bold)
        
        ZStack {
            if todaySelfConsumptionRate != nil {
                VStack(alignment: .center) {
                    GeometryReader { proxy in
                        let radius =
                        proxy.size.width < proxy.size.height
                        ? proxy.size.width / 2
                        : proxy.size.height / 2
                        
                        let offsetY = (proxy.size.height / 2) + radius + 10
                        
                        Text("Self consumption: \(percent)")
                            .font(.subheadline)
                            .frame(width: proxy.size.width)
                            .multilineTextAlignment(.center)
                            .offset(y: offsetY)
                        
                    }
                }
            }
            
            CircularInstrument(
                borderColor: currentSolarProductionInKwh != 0 ? .accentColor : .gray,
                label: "Solar Production",
                value: String(format: "%.1f kW", currentSolarProductionInKwh)
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
}

#Preview("W. Self-Consumption") {
    SolarBoubleView(
        currentSolarProductionInKwh: 5.4,
        todaySolarProductionInWh: 15500,
        todaySelfConsumptionRate: 66
    )
        .frame(width: 150, height:  150)
}

#Preview("W/o Self-Consumption") {
    SolarBoubleView(
        currentSolarProductionInKwh: 5.4,
        todaySolarProductionInWh: 15500,
        todaySelfConsumptionRate: nil
    )
        .frame(width: 150, height:  150)
}
