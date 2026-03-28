import SwiftUI

struct GridSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.energyManager) var energyManager

    @State private var mainData: MainData?
    @State private var tariff: TariffV1Response?
    @State private var tariffSettings: TariffSettingsV3Response?
    @State private var weekData: [DayGridSummary] = []
    @State private var isLoadingWeek = true

    var body: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(red: 0.06, green: 0.04, blue: 0.10), Color(red: 0.05, green: 0.05, blue: 0.05)]
                    : [Color(red: 0.95, green: 0.93, blue: 0.98), .white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    GridTodayCard(
                        mainData: mainData,
                        tariffSettings: tariffSettings,
                        fallbackTariff: tariff
                    )

                    if isLoadingWeek {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical)
                    } else if !weekData.isEmpty {
                        GridWeekCard(
                            weekData: weekData,
                            tariffSettings: tariffSettings,
                            fallbackTariff: tariff
                        )
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Grid")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundColor(.purple)
                }
            }
        }
        .task {
            await fetchData()
        }
    }

    private func fetchData() async {
        async let mainDataTask = try? energyManager.fetchMainData(
            from: Date.todayStartOfDay(),
            to: Date.todayEndOfDay()
        )
        async let tariffTask = try? energyManager.fetchTariff()
        async let tariffSettingsTask = try? energyManager.fetchDetailedTariffs()

        let (fetchedMain, fetchedTariff, fetchedSettings) = await (
            mainDataTask, tariffTask, tariffSettingsTask
        )
        self.mainData = fetchedMain
        self.tariff = fetchedTariff
        self.tariffSettings = fetchedSettings

        // Fetch 7 days of data
        await fetchWeekData()
    }

    private func fetchWeekData() async {
        let calendar = Calendar.current
        var summaries: [DayGridSummary] = []

        for daysAgo in 1...7 {
            let dayStart = calendar.date(
                byAdding: .day, value: -daysAgo,
                to: calendar.startOfDay(for: Date())
            )!
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

            if let data = try? await energyManager.fetchMainData(
                from: dayStart, to: dayEnd)
            {
                summaries.append(
                    DayGridSummary(id: dayStart, date: dayStart, data: data.data)
                )
            }
        }

        self.weekData = summaries
        self.isLoadingWeek = false
    }
}

#Preview {
    NavigationView {
        GridSheet()
    }
}
