import SwiftUI

struct SolarDetailsView: View {
    @StateObject var viewModel = SolarDetailsViewModel()
    @EnvironmentObject var buildingModel: BuildingStateViewModel
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

                    Button(action: {
                        viewModel.fetchingIsPaused = true
                        buildingModel.pauseFetching()
                        print("Show solar chart sheet")
                        showSolarChart = true
                    }) {
                        Image(systemName: "chart.line.uptrend.xyaxis.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .symbolEffect(.breathe.pulse.byLayer, options: .repeat(.continuous))
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.primary)
                    .padding(.leading, 20)
                    .sheet(isPresented: $showSolarChart) {
                        SolarChartView(
                            maxProductionkW: $viewModel.overviewData.solarProductionMax
                        )
                        .onDisappear {
                            print("Hide solar chart sheet")
                            viewModel.fetchingIsPaused = false
                            buildingModel.resumeFetching()
                        }
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                    Text("Production")
                                        .foregroundColor(.accent)
                                        .font(.headline)
                            }  // :ToolbarItem
                        }  // :.toolbar
                    }
                }

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
                            date: .constant(
                                Calendar.current.startOfDay(for: Date())),
                            maxProduction: $viewModel.overviewData
                                .solarProductionMax,
                            forecast: $viewModel.solarDetailsData
                                .forecastToday,
                            small: .constant(false)
                        )

                        ForecastItemView(
                            date: .constant(
                                Calendar.current.date(
                                    byAdding: .day, value: 1, to: Date())),
                            maxProduction: $viewModel.overviewData
                                .solarProductionMax,
                            forecast: $viewModel.solarDetailsData
                                .forecastTomorrow,
                            small: .constant(false)
                        )

                        ForecastItemView(
                            date: .constant(
                                Calendar.current.date(
                                    byAdding: .day, value: 2, to: Date())),
                            maxProduction: $viewModel.overviewData
                                .solarProductionMax,
                            forecast: $viewModel.solarDetailsData
                                .forecastDayAfterTomorrow,
                            small: .constant(false)
                        )
                    }  // :HStack
                    .frame(maxWidth: .infinity)

                }  // :if

                Spacer()
            }  // :VStack
            .padding(.horizontal, 2)
            .frame(maxHeight: .infinity)

            VStack {
                Spacer()

                UpdateTimeStampView(
                    isStale: $viewModel.overviewData.isStaleData,
                    updateTimeStamp: $viewModel.overviewData.lastUpdated,
                    isLoading: $viewModel.isLoading
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
                    withTimeInterval: 15, repeats: true
                ) {
                    _ in
                    Task {
                        await viewModel.fetchSolarDetails()
                    }
                }  // :refreshTimer
            }  // :if

            AppStoreReviewManager.shared.setSolarDetailsShownAtLeastOnce()
        }  // :onAppear
        .onDisappear() {
            refreshTimer?.invalidate()
            refreshTimer = nil
        }
    }

    private func getDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        return formatter
    }
}

#Preview("Normal") {
    SolarDetailsView(viewModel: SolarDetailsViewModel.previewFake())
}
