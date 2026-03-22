import SwiftUI

struct HomePortraitLayout: View {
    @Environment(CurrentBuildingState.self) var buildingState: CurrentBuildingState
    @Binding var showError: Bool
    let solarDetailsData: SolarDetailsData?
    let onRefresh: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HeaderView(onRefresh: onRefresh, showError: $showError)
                .padding(.top, 65)

            Spacer()

            EnergyFlowGrid(showCharging: true)
                .padding(.horizontal, 16)

            Spacer()

            HStack(alignment: .bottom, spacing: 16) {
                if let solarDetailsData {
                    SolarForecastView(
                        solarProductionMax: buildingState.overviewData.solarProductionMax,
                        todaySolarProduction: solarDetailsData.todaySolarProduction,
                        forecastToday: solarDetailsData.forecastToday,
                        forecastTomorrow: solarDetailsData.forecastTomorrow,
                        forecastDayAfterTomorrow: solarDetailsData.forecastDayAfterTomorrow
                    )
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)
                }

                EfficiencyGaugeView(
                    todaySelfConsumptionRate: buildingState.overviewData.todaySelfConsumptionRate,
                    todayAutarchyDegree: buildingState.overviewData.todayAutarchyDegree
                )
                .cardStyle()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            FooterView()
        }
        .transaction { transaction in
            transaction.animation = nil
        }
    }
}

#Preview {
    HomePortraitLayout(
        showError: .constant(false),
        solarDetailsData: SolarDetailsData.fake(),
        onRefresh: {}
    )
    .environment(
        CurrentBuildingState.fake(
            overviewData: OverviewData.fake()
        )
    )
}
