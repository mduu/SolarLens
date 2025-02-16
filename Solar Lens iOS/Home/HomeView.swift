import SwiftUI

struct HomeView: View {
    @Environment(CurrentBuildingState.self) var buildingState:
        CurrentBuildingState
    @Environment(\.energyManager) var energyManager
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @State var refreshTimer: Timer?
    @State var solarForecastTimer: Timer?
    @State var solarDetailsData: SolarDetailsData?

    var body: some View {
        VStack {

            if buildingState.isLoading
                && buildingState.overviewData.lastSuccessServerFetch == nil
            {
                ProgressView()
                    .tint(.accent)
                    .padding()
                    .foregroundStyle(.accent)
                    .background(Color.black.opacity(0.3))
            } else {
                ZStack {

                    BackgroundView()

                    VStack {
                        HeaderView()
                            .padding(
                                .top, horizontalSizeClass == .compact ? 60 : 0)
                        Spacer()
                        FooterView()
                    }
                    .ignoresSafeArea()

                    VStack {

                        HStack {
                            if solarDetailsData != nil {
                                SolarForecastView(
                                    solarProductionMax: buildingState
                                        .overviewData.solarProductionMax,
                                    todaySolarProduction: solarDetailsData!
                                        .todaySolarProduction,
                                    forecastToday: solarDetailsData!
                                        .forecastToday,
                                    forecastTomorrow: solarDetailsData!
                                        .forecastTomorrow,
                                    forecastDayAfterTomorrow:
                                        solarDetailsData!
                                        .forecastDayAfterTomorrow
                                )
                                .frame(maxWidth: 180, maxHeight: 120)
                                .padding(.leading, 5)
                            }

                            Spacer()
                        }  // :HStack
                        .padding()

                        EnergyFlow()

                        HStack {

                            Spacer()

                            ChargingView(
                                isVertical: horizontalSizeClass == .compact
                            )

                        }  // :HStack
                        .padding()

                    }  // :VStack

                }  // :ZStack
            }
        }
        .onAppear {
            fetchAndStartRefreshTimerForOverviewData()
            fetchAndStartRefreshTimerForSolarDetailData()
        }
    }

    private func fetchAndStartRefreshTimerForOverviewData() {
        if buildingState.overviewData.lastSuccessServerFetch == nil {
            print("initial fetch overview data")
            Task {
                await buildingState.fetchServerData()
            }
        }

        if refreshTimer == nil {
            refreshTimer = Timer.scheduledTimer(
                withTimeInterval: 15, repeats: true
            ) {
                _ in
                Task {
                    print("fetch on timer")
                    await buildingState.fetchServerData()
                }
            }
        }
    }

    private func fetchAndStartRefreshTimerForSolarDetailData() {
        if solarDetailsData == nil {
            print("fetch solarDetailsData on appear")
            Task {
                solarDetailsData = try await energyManager.fetchSolarDetails()
            }
        }
        if solarForecastTimer == nil {
            solarForecastTimer = Timer.scheduledTimer(
                withTimeInterval: 300, repeats: true
            ) {
                _ in
                Task { @MainActor in
                    print("fetch solarDetailsData on timer")
                    solarDetailsData =
                        try await energyManager.fetchSolarDetails()
                }
            }
        }
    }
}

#Preview {
    HomeView(
        solarDetailsData: SolarDetailsData.fake()
    )
    .environment(
        CurrentBuildingState.fake(
            overviewData: OverviewData.fake()))
}
