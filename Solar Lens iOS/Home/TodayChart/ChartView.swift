import SwiftUI

struct ChartView: View {
    @Environment(CurrentBuildingState.self) var buildingModel: CurrentBuildingState
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @AppStorage("todayShowProduction") private var showProduction: Bool = true
    @AppStorage("todayShowConsumption") private var showConsumption: Bool = true
    @AppStorage("showBatteryCharging") private var showBatteryCharging: Bool = false
    @AppStorage("showBatteryDischarging") private var showBatteryDischarging: Bool = false
    @AppStorage("showBatteryPercentag") private var showBatteryPercentage: Bool = true

    /// Both owned by the presenting sheet: the day switcher lives in its
    /// navigation bar, so it needs the same navigator and loading state.
    let navigator: ChartTimeNavigator
    let store: IntradayChartStore

    @State private var refreshTimer: Timer?

    /// The marks the chart draws. Held as one long-lived object, refreshed
    /// only after a load: handing Swift Charts a freshly built series on every
    /// render makes it re-anchor its scroll offset.
    @State private var chartData = MainData(data: [])
    @State private var chartBatteries: [BatteryHistory] = []
    @State private var futureShading: ChartFutureShading?

    private var isLandscape: Bool { verticalSizeClass == .compact }

    /// The samples the visible day actually holds — everything below reads
    /// from here, so the numbers always describe what is on screen.
    private var visibleItems: [MainDataItem] {
        store.items(in: navigator.window)
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                VStack {
                    if visibleItems.isEmpty && !store.isLoading {
                        Spacer()
                        Text("No data")
                            .font(.footnote)
                        Spacer()
                    } else if isLandscape {
                        landscapeContent
                    } else {
                        portraitContent
                    }
                }
                .padding(8)

                if store.isLoading && visibleItems.isEmpty {
                    ProgressView()
                        .tint(.accent)
                        .frame(width: 50, height: 50)
                        .padding()
                }
            }
        }
        .task(id: navigator.windowStart) {
            // Scrolling walks through days quickly; settle first so a flick
            // across a week does not fire a request per day passed.
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            await store.ensureLoaded(around: navigator.window)
            refreshChartData()
        }
        .task {
            await applyEarliestDate()
        }
        .onAppear {
            if refreshTimer == nil {
                refreshTimer = Timer.scheduledTimer(
                    withTimeInterval: 300,
                    repeats: true
                ) { _ in
                    Task { @MainActor in
                        guard navigator.isAtPresent else { return }
                        store.invalidateToday()
                        await store.ensureLoaded(around: navigator.window)
                        refreshChartData()
                    }
                }
            }
        }
        .onDisappear {
            refreshTimer?.invalidate()
            refreshTimer = nil
        }
    }

    // MARK: - Portrait

    private var portraitContent: some View {
        VStack(spacing: 12) {
            chartWithToggles

            HStack(spacing: 12) {
                infoCards
            }
        }
    }

    // MARK: - Landscape

    private var landscapeContent: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 8) {
                chartWithToggles
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 12) {
                infoCards
            }
            .frame(width: 200)
        }
    }

    // MARK: - Shared Components

    private var chartWithToggles: some View {
        VStack(spacing: 12) {
            OverviewChart(
                consumption: chartData,
                batteries: chartBatteries,
                showProduction: showProduction,
                showConsumption: showConsumption,
                showBatteryCharge: showBatteryCharging,
                showBatteryDischange: showBatteryDischarging,
                showBatteryPercentage: showBatteryPercentage,
                showLegend: false,
                scrollConfig: navigator.scrollConfig(),
                yMaxOverride: yMax,
                futureShading: futureShading
            )

            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    SeriesToggle(label: "Production", color: .yellow, isOn: $showProduction)
                    SeriesToggle(label: "Consumption", color: .teal, isOn: $showConsumption)
                }
                HStack(spacing: 6) {
                    SeriesToggle(label: "Battery %", color: SerieColors.batteryLevelColor(useAlternativeColors: false), isOn: $showBatteryPercentage)
                    SeriesToggle(label: "Charged", color: .purple, isOn: $showBatteryCharging)
                    SeriesToggle(label: "Discharged", color: .indigo, isOn: $showBatteryDischarging)
                }
            }
        }
    }

    @ViewBuilder
    private var infoCards: some View {
        let isToday = navigator.isAtPresent

        TodaySolarView(
            peakProductionInW: getMaxProductionkW(),
            currentSolarProductionInW: isToday
                ? buildingModel.overviewData.currentSolarProduction : nil,
            todaySolarProductionInWh: visibleItems.reduce(0) {
                $0 + $1.productionOverTimeWatthours
            }
        )

        TodayConsumptionView(
            peakConsumptionInW: getMaxConsumptionkW(),
            currentConsumptionInW: isToday
                ? buildingModel.overviewData.currentOverallConsumption : nil,
            todayConsumptionInWh: visibleItems.reduce(0) {
                $0 + $1.consumptionOverTimeWatthours
            }
        )
    }

    // MARK: - Helpers

    private func refreshChartData() {
        chartData.data = store.marks(around: navigator.window)
        chartBatteries = store.batteryMarks(around: navigator.window)
        futureShading = ChartFutureShading(window: navigator.window)
    }

    /// Peak of the visible day, so scrolling onto an overcast day does not
    /// squash its curve against the axis of a sunny neighbour.
    private var yMax: Double? {
        let peak = visibleItems
            .map { max($0.productionWatts, $0.consumptionWatts) / 1000 }
            .max()
        guard let peak, peak > 0.005 else { return nil }
        return peak * 1.1
    }

    private func getMaxProductionkW() -> Double {
        visibleItems.map { $0.productionWatts / 1000 }.max() ?? 0
    }

    private func getMaxConsumptionkW() -> Double {
        visibleItems.map { $0.consumptionWatts / 1000 }.max() ?? 0
    }

    /// Stops the user from scrolling back past the day the Solar Manager
    /// installation was registered — there is no data before that.
    private func applyEarliestDate() async {
        guard let info = try? await SolarManager.shared.fetchServerInfo(),
            let registered = info.registrationDate
        else { return }
        navigator.setEarliest(registered)
    }
}

#Preview {
    ChartView(
        navigator: ChartTimeNavigator(page: .day),
        store: IntradayChartStore(energyManager: FakeEnergyManager.instance())
    )
    .frame(maxHeight: 350)
    .environment(
        CurrentBuildingState.fake(
            overviewData: OverviewData.fake()
        )
    )
}
