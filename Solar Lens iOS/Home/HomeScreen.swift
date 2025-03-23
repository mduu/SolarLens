import SwiftUI

struct HomeScreen: View {
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

                    if verticalSizeClass != .compact {
                        VStack {
                            HeaderView()
                                .padding(.top, 0)
                            Spacer()

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
                                .padding(.horizontal, 50)

                            HStack {

                                Spacer()

                                ChargingView(
                                    isVertical: true
                                )

                            }  // :HStack
                            .padding()

                            Spacer()

                            FooterView()

                        }  // :VStack
                    } else {
                        HStack {

                            VStack {

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
                            }  // :VStack
                            .padding(.trailing)

                            EnergyFlow()

                            VStack {
                                HStack(alignment: .center) {
                                    AppLogo()
                                    LogoutButtonView()
                                        .padding(.leading, 5)
                                }
                                .padding(.trailing, -30)

                                Spacer()

                                ChargingView(
                                    isVertical: false
                                )
                            }  // :VStack

                        }  // :HStack
                        .padding(.top)
                    }  // :else

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
    HomeScreen(
        solarDetailsData: SolarDetailsData.fake()
    )
    .environment(
        CurrentBuildingState.fake(
            overviewData: OverviewData.fake()))
}
