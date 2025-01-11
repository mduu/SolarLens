import SwiftUI

struct SolarForecastView: View {
    @StateObject private var viewModel: SolarDetailsViewModel = .init()
    @State private var refreshTimer: Timer?

    var body: some View {
        VStack {
            Text("Forecast")
                .font(.headline)
                .foregroundColor(.accent)
            
            HStack {
                ForecastItemView(
                    date: .constant(
                        Calendar.current.startOfDay(for: Date())),
                    maxProduction: $viewModel.overviewData
                        .solarProductionMax,
                    forecasts: .constant([
                        viewModel.solarDetailsData.forecastToday,
                        viewModel.solarDetailsData.forecastTomorrow,
                        viewModel.solarDetailsData
                            .forecastDayAfterTomorrow,
                    ]),
                    forecast: $viewModel.solarDetailsData
                        .forecastToday,
                    small: .constant(false),
                    intense: true
                )
                
                ForecastItemView(
                    date: .constant(
                        Calendar.current.date(
                            byAdding: .day, value: 1, to: Date())),
                    maxProduction: $viewModel.overviewData
                        .solarProductionMax,
                    forecasts: .constant([
                        viewModel.solarDetailsData.forecastToday,
                        viewModel.solarDetailsData.forecastTomorrow,
                        viewModel.solarDetailsData
                            .forecastDayAfterTomorrow,
                    ]),
                    forecast: $viewModel.solarDetailsData
                        .forecastTomorrow,
                    small: .constant(false),
                    intense: true
                )
                
                ForecastItemView(
                    date: .constant(
                        Calendar.current.date(
                            byAdding: .day, value: 2, to: Date())),
                    maxProduction: $viewModel.overviewData
                        .solarProductionMax,
                    forecasts: .constant([
                        viewModel.solarDetailsData.forecastToday,
                        viewModel.solarDetailsData.forecastTomorrow,
                        viewModel.solarDetailsData
                            .forecastDayAfterTomorrow,
                    ]),
                    forecast: $viewModel.solarDetailsData
                        .forecastDayAfterTomorrow,
                    small: .constant(false),
                    intense: true
                )
            } // :HStack
        } // :VStack
        .onAppear {
            Task {
                await viewModel.fetchSolarDetails()
            }

            if refreshTimer == nil {
                refreshTimer = Timer.scheduledTimer(
                    withTimeInterval: 120, repeats: true
                ) {
                    _ in
                    Task {
                        await viewModel.fetchSolarDetails()
                    }
                }  // :refreshTimer
            }  // :if

            AppStoreReviewManager.shared.setSolarDetailsShownAtLeastOnce()
        }  // :onAppear
    }
}

#Preview {
    SolarForecastView()
}
