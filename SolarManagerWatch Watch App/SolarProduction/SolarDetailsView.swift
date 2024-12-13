import SwiftUI

struct SolarDetailsView: View {
    @StateObject var viewModel = SolarDetailsViewModel()

    var body: some View {
        ZStack {

            LinearGradient(
                gradient: Gradient(colors: [
                    .orange.opacity(0.5), .orange.opacity(0.2),
                ]), startPoint: .top, endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            ScrollView {
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
                        }
                        .frame(maxWidth: .infinity)

                    }  // :if
                }  // :VStack
                .padding(.horizontal, 2)

            }  // :ScrollView

            if viewModel.isLoading {
                ProgressView()
            }

        }  // :ZStack
        .onAppear {
            Task {
                await viewModel.fetchSolarDetails()
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
    SolarDetailsView(viewModel: SolarDetailsViewModel.previewFake())
}
