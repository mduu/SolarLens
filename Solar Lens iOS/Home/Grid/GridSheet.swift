import SwiftUI

struct GridSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.energyManager) var energyManager

    @State private var tariff: TariffV1Response?
    @State private var tariffSettings: TariffSettingsV3Response?

    @State private var navigator = ChartTimeNavigator(page: .day)
    @State private var store = IntradayChartStore(includeBatteryHistory: false)

    /// The marks the chart draws. Held as one long-lived object, refreshed
    /// only after a load: handing Swift Charts a freshly built series on every
    /// render makes it re-anchor its scroll offset.
    @State private var chartData = MainData(data: [])
    @State private var futureShading: ChartFutureShading?

    /// The seven days ending on the day the chart shows.
    private var weekRange: Range<Date> {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .day, value: -6, to: navigator.windowStart)
            ?? navigator.windowStart
        return start..<navigator.windowEnd
    }

    /// Rebuilt only after a load, never on every render: the cost card runs a
    /// tariff calculation over ~2,000 samples per day, which is far too much
    /// to redo while the chart is being scrolled.
    @State private var weekData: [DayGridSummary] = []

    private func rebuildWeekData() {
        let calendar = Calendar.current
        var day = weekRange.lowerBound
        var summaries: [DayGridSummary] = []
        while day < weekRange.upperBound {
            let samples = store.samples(on: day)
            if !samples.isEmpty {
                summaries.append(DayGridSummary(id: day, date: day, data: samples))
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        weekData = summaries
    }

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

            VStack(spacing: 0) {
                ChartTimeHeader(navigator: navigator, isLoading: store.isLoading)
                    .padding(.horizontal)
                    .padding(.top, 8)

                ScrollView {
                    VStack(spacing: 16) {
                        GridTodayCard(
                            mainData: chartData,
                            tariffSettings: tariffSettings,
                            fallbackTariff: tariff,
                            window: navigator.window,
                            windowLabel: navigator.windowLabel,
                            scrollConfig: navigator.scrollConfig(),
                            futureShading: futureShading
                        )

                        if weekData.isEmpty {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical)
                        } else {
                            GridWeekCard(
                                weekData: weekData,
                                tariffSettings: tariffSettings,
                                fallbackTariff: tariff,
                                endDate: navigator.isAtPresent
                                    ? nil
                                    : Calendar.current.date(
                                        byAdding: .day, value: -1, to: navigator.windowEnd
                                    )
                            )
                        }
                    }
                    .padding()
                }
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
        .task(id: navigator.windowStart) {
            // Scrolling walks through days quickly; settle first so a flick
            // across a week does not fire a request per day passed.
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            await store.ensureLoaded(days: weekRange)
            rebuildWeekData()
            chartData.data = store.marks(around: navigator.window)
            futureShading = ChartFutureShading(window: navigator.window)
        }
        .task {
            await fetchTariffs()
            await applyEarliestDate()
        }
    }

    private func fetchTariffs() async {
        async let tariffTask = try? energyManager.fetchTariff()
        async let tariffSettingsTask = try? energyManager.fetchDetailedTariffs()

        let (fetchedTariff, fetchedSettings) = await (tariffTask, tariffSettingsTask)
        self.tariff = fetchedTariff
        self.tariffSettings = fetchedSettings
    }

    /// Stops the user from scrolling back past the day the Solar Manager
    /// installation was registered — there is no data before that.
    private func applyEarliestDate() async {
        guard let info = try? await energyManager.fetchServerInfo(),
            let registered = info.registrationDate
        else { return }
        navigator.setEarliest(registered)
    }
}

#Preview {
    NavigationView {
        GridSheet()
    }
}
