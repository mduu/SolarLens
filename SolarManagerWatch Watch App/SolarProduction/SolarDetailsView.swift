import SwiftUI

struct SolarDetailsView: View {
    @StateObject var viewModel = SolarDetailsViewModel()
    @State private var refreshTimer: Timer?

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

                SolarInfoView(
                    totalProducedToday: .constant(total),
                    currentProduction: .constant(current)
                )

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
                                .forecastToday
                        )

                        ForecastItemView(
                            date: .constant(
                                Calendar.current.date(
                                    byAdding: .day, value: 1, to: Date())),
                            maxProduction: $viewModel.overviewData
                                .solarProductionMax,
                            forecast: $viewModel.solarDetailsData
                                .forecastTomorrow
                        )

                        ForecastItemView(
                            date: .constant(
                                Calendar.current.date(
                                    byAdding: .day, value: 2, to: Date())),
                            maxProduction: $viewModel.overviewData
                                .solarProductionMax,
                            forecast: $viewModel.solarDetailsData
                                .forecastDayAfterTomorrow
                        )
                    } // :HStack
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
                    print("Refresh solar details")
                    Task {
                        await viewModel.fetchSolarDetails()
                    }
                }  // :refreshTimer
            }  // :if
        }  // :onAppear
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
