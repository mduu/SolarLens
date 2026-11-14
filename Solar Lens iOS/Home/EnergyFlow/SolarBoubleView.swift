import SwiftUI

struct SolarBoubleView: View {
    var currentSolarProductionInKwh: Double
    var todaySolarProductionInWh: Double?

    @State var isChartSheetShown: Bool = false
    @Environment(HomeDetailRouter.self) private var router: HomeDetailRouter?

    var body: some View {
        let todayKwh = (todaySolarProductionInWh ?? 0) / 1000

        let todayFormatted = todayKwh.localized(decimals: 1)

        Button {
            if router?.open(.production) != true { isChartSheetShown = true }
        } label: {
            EnergyCard(
                icon: "sun.max.fill",
                iconColor: .orange,
                label: "Production",
                value: "\(currentSolarProductionInKwh.localized(decimals: 1)) kW",
                detail: "\(todayFormatted) kWh today",
                showChevron: true
            )
        }
        .buttonStyle(CardButtonStyle())
        .detailSelection(router?.detail == .production)
        .sheet(isPresented: $isChartSheetShown) {
            NavigationStack {
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
