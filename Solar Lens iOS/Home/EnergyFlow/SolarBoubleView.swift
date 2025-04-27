import SwiftUI

struct SolarBoubleView: View {
    var currentSolarProductionInKwh: Double
    var todaySolarProductionInWh: Double?
    var useGlow: Bool

    @State var isChartSheetShown: Bool = false

    var body: some View {
        CircularInstrument(
            borderColor: currentSolarProductionInKwh != 0
                ? .accentColor : .gray,
            label: "Production",
            value: String(format: "%.1f kW", currentSolarProductionInKwh),
            isTouchable: true,
            useGlowEffect: useGlow
        ) {
            VStack {
                TodayValue(valueInWh: todaySolarProductionInWh ?? 0)
                
                Image(systemName: "sun.max")
                    .foregroundColor(.black)
            }
        }
        .onTapGesture
        {
            isChartSheetShown = true
        }
        .sheet(isPresented: $isChartSheetShown) {
            NavigationView {
                TodayChartSheet()
            }
            .presentationDetents([.medium, .large])
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
