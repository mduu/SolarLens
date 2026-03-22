import SwiftUI

struct HomeLandscapeLayout: View {
    @Environment(CurrentBuildingState.self) var buildingState: CurrentBuildingState
    let solarDetailsData: SolarDetailsData?
    let onRefresh: () -> Void

    private let columnSpacing: CGFloat = 12
    private let compactButtonSize: CGFloat = 32

    var body: some View {
        HStack(alignment: .top, spacing: columnSpacing) {
            // Columns 1 & 2: Energy Flow Grid with Efficiency below battery
            EnergyFlowGrid {
                EfficiencyGaugeView(
                    todaySelfConsumptionRate: buildingState.overviewData.todaySelfConsumptionRate,
                    todayAutarchyDegree: buildingState.overviewData.todayAutarchyDegree,
                    compact: true
                )
                .cardStyle()
            }
            .frame(maxWidth: .infinity)

            // Column 3: App controls + Charging + Forecast
            VStack(spacing: 8) {
                // Compact header: app icon, timestamp, refresh, settings
                HStack(spacing: 6) {
                    Image("solarlens")
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(4)
                        .frame(width: 28, height: 28)

                    Spacer()

                    UpdateTimeStampView(
                        isStale: buildingState.overviewData.isStaleData,
                        updateTimeStamp: buildingState.overviewData.lastSuccessServerFetch,
                        isLoading: buildingState.isLoading,
                        onRefresh: nil
                    )
                    .font(.caption2)
                    .lineLimit(1)

                    RoundIconButton(
                        imageName: "arrow.trianglehead.counterclockwise",
                        buttonSize: compactButtonSize
                    ) {
                        onRefresh()
                    }

                    SettingsButton(buttonSize: compactButtonSize)
                }

                if !buildingState.overviewData.chargingStations.isEmpty {
                    ChargingView(isVertical: true)
                }

                forecastCard
            }
            .frame(width: 190)
        }
    }

    @ViewBuilder
    private var forecastCard: some View {
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
                .frame(height: 100)
                .cardStyle()
        }
    }
}

#Preview {
    HomeLandscapeLayout(
        solarDetailsData: SolarDetailsData.fake(),
        onRefresh: {}
    )
    .padding()
    .environment(
        CurrentBuildingState.fake(
            overviewData: OverviewData.fake()
        )
    )
}
