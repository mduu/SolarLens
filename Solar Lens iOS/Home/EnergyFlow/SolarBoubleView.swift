import SwiftUI

struct SolarBoubleView: View {
    var currentSolarProductionInKwh: Double
    var todaySolarProductionInWh: Double?

    @State var isChartSheetShown: Bool = false

    var body: some View {
        let todayKwh = (todaySolarProductionInWh ?? 0) / 1000

        EnergyCard(
            icon: "sun.max.fill",
            iconColor: .orange,
            label: "Production",
            value: String(format: "%.1f kW", currentSolarProductionInKwh),
            detail: String(format: "%.1f kWh today", todayKwh),
            showChevron: true
        )
        .onTapGesture { isChartSheetShown = true }
        .sheet(isPresented: $isChartSheetShown) {
            NavigationView {
                TodayChartSheet()
            }
            .presentationDetents([.medium, .large])
        }
    }
}

#Preview("Default") {
    SolarBoubleView(
        currentSolarProductionInKwh: 5.4,
        todaySolarProductionInWh: 15500,
    )
    .padding()
}
