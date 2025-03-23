import SwiftUI

struct SolarScreen: View {
    @Environment(CurrentBuildingState.self) var buildingModel: CurrentBuildingState
    @State var viewModel = SolarScreenViewModel()
    @State private var refreshTimer: Timer?
    @State private var showSolarChart: Bool = false

    var body: some View {
        ZStack {

            LinearGradient(
                gradient: Gradient(colors: [
                    .orange.opacity(0.5), .orange.opacity(0.2),
                ]), startPoint: .top, endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            VStack {
                let current = Int?(
                    viewModel.overviewData.currentSolarProduction)
                let total = viewModel.solarDetailsData.todaySolarProduction

                HStack {
                    SolarTodayInfoView(
                        totalProducedToday: .constant(total),
                        currentProduction: .constant(current)
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 4)

                    RoundChartButton {
                        viewModel.fetchingIsPaused = true
                        buildingModel.pauseFetching()
                        
                        withAnimation {
                            showSolarChart = true
                        }
                    }
                    
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)

                if viewModel.solarDetailsData.forecastToday != nil
                    || viewModel.solarDetailsData.forecastTomorrow != nil
                    || viewModel.solarDetailsData.forecastDayAfterTomorrow
                        != nil
                {

                    Divider()

                    Text("Forecast")
                        .font(.headline)
                        .padding(.top, 4)

                    HStack {
                        ForecastItemView(
                            date:
                                Calendar.current.startOfDay(for: Date()),
                            maxProduction:
                                viewModel.overviewData.solarProductionMax,
                            forecasts: [
                                viewModel.solarDetailsData.forecastToday,
                                viewModel.solarDetailsData.forecastTomorrow,
                                viewModel.solarDetailsData
                                    .forecastDayAfterTomorrow,
                            ],
                            forecast:
                                viewModel.solarDetailsData.forecastToday,
                            small: false
                        )

                        ForecastItemView(
                            date:
                                Calendar.current.date(byAdding: .day, value: 1, to: Date()),
                            maxProduction:
                                viewModel.overviewData.solarProductionMax,
                            forecasts: [
                                viewModel.solarDetailsData.forecastToday,
                                viewModel.solarDetailsData.forecastTomorrow,
                                viewModel.solarDetailsData
                                    .forecastDayAfterTomorrow,
                            ],
                            forecast:
                                viewModel.solarDetailsData.forecastTomorrow,
                            small: false
                        )

                        ForecastItemView(
                            date:
                                Calendar.current.date(
                                    byAdding: .day, value: 2, to: Date()),
                            maxProduction:
                                viewModel.overviewData.solarProductionMax,
                            forecasts: [
                                viewModel.solarDetailsData.forecastToday,
                                viewModel.solarDetailsData.forecastTomorrow,
                                viewModel.solarDetailsData
                                    .forecastDayAfterTomorrow,
                            ],
                            forecast:
                                viewModel.solarDetailsData.forecastDayAfterTomorrow,
                            small: false
                        )
                    }  // :HStack
                    .frame(maxWidth: .infinity)

                }  // :if

                Spacer()
            }  // :VStack
            .frame(maxHeight: .infinity)
            .padding(.leading, 2)
            .padding(.trailing, 10)

            VStack {
                Spacer()

                UpdateTimeStampView(
                    isStale: viewModel.overviewData.isStaleData,
                    updateTimeStamp: viewModel.overviewData.lastUpdated,
                    isLoading: viewModel.isLoading
                )
                .padding(.vertical, 4)
            }
            .ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
                    .tint(.accent)
                    .padding()
                    .foregroundStyle(.accent)
                    .background(Color.black.opacity(0.7))
            }

        }  // :ZStack
        .onAppear {
            Task {
                await viewModel.fetchSolarDetails()
            }

            if refreshTimer == nil {
                refreshTimer = Timer.scheduledTimer(
                    withTimeInterval: 60, repeats: true
                ) {
                    _ in
                    Task {
                        await viewModel.fetchSolarDetails()
                    }
                }  // :refreshTimer
            }  // :if

            AppStoreReviewManager.shared.setSolarDetailsShownAtLeastOnce()
        }  // :onAppear
        .onDisappear {
            refreshTimer?.invalidate()
            refreshTimer = nil
        }
        .sheet(isPresented: $showSolarChart) {
            SolarChartView(
                maxProductionkW: $viewModel.overviewData.solarProductionMax
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text("Production")
                        .foregroundColor(.accentColor)
                        .font(.headline)
                }  // :ToolbarItem
            }  // :.toolbar
            .onDisappear {
                print("Hide solar chart sheet")
                viewModel.fetchingIsPaused = false
                buildingModel.resumeFetching()
            }
        }
        
    }

    private func getDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        return formatter
    }
}

#Preview("Normal") {
    SolarScreen(viewModel: SolarScreenViewModel.previewFake())
        .environment(CurrentBuildingState.fake())
}
