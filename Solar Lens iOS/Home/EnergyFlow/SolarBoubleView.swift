import SwiftUI

struct SolarBoubleView: View {
    var currentSolarProductionInKwh: Double
    var todaySolarProductionInWh: Double?

    @State var isChartSheetShown: Bool = false

    var body: some View {
        let todayKwh = (todaySolarProductionInWh ?? 0) / 1000

        let todayFormatted = String(format: "%.1f", todayKwh)

        EnergyCard(
            icon: "sun.max.fill",
            iconColor: .orange,
            label: "Production",
            value: String(format: "%.1f kW", currentSolarProductionInKwh),
            detail: "\(todayFormatted) kWh today",
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
