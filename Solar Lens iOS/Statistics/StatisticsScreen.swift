import Charts
import SwiftUI

struct StatisticsScreen: View {
    @Environment(CurrentBuildingState.self) var buildingState: CurrentBuildingState
    @State private var viewModel = StatisticsViewModel()
    @State private var shareURLs: [URL] = []
    @State private var showShareSheet = false
    @State private var showExportFormatPicker = false
    @State private var isExporting = false

    /// The marks the charts draw. Refreshed only after a load, so a render
    /// triggered by anything else does not hand Swift Charts a freshly built
    /// series to lay out again.
    @State private var intradayData = MainData(data: [])
    @State private var intradayBatteries: [BatteryHistory] = []
    @State private var barMarks: [DayStatistic] = []
    @State private var visibleBars: [DayStatistic] = []
    @State private var futureShading: ChartFutureShading?

    // Persisted series visibility per period
    @AppStorage("stats.week.showProduction") private var weekShowProduction = true
    @AppStorage("stats.week.showConsumption") private var weekShowConsumption = true
    @AppStorage("stats.week.showImport") private var weekShowImport = true
    @AppStorage("stats.week.showExport") private var weekShowExport = true

    @AppStorage("stats.month.showProduction") private var monthShowProduction = true
    @AppStorage("stats.month.showConsumption") private var monthShowConsumption = true
    @AppStorage("stats.month.showImport") private var monthShowImport = true
    @AppStorage("stats.month.showExport") private var monthShowExport = true

    @AppStorage("stats.year.showProduction") private var yearShowProduction = true
    @AppStorage("stats.year.showConsumption") private var yearShowConsumption = true
    @AppStorage("stats.year.showImport") private var yearShowImport = true
    @AppStorage("stats.year.showExport") private var yearShowExport = true

    @AppStorage("stats.overall.showProduction") private var overallShowProduction = true
    @AppStorage("stats.overall.showConsumption") private var overallShowConsumption = true
    @AppStorage("stats.overall.showImport") private var overallShowImport = true
    @AppStorage("stats.overall.showExport") private var overallShowExport = true

    @AppStorage("stats.custom.showProduction") private var customShowProduction = true
    @AppStorage("stats.custom.showConsumption") private var customShowConsumption = true
    @AppStorage("stats.custom.showImport") private var customShowImport = true
    @AppStorage("stats.custom.showExport") private var customShowExport = true

    @AppStorage("stats.today.showProduction") private var todayShowProduction = true
    @AppStorage("stats.today.showConsumption") private var todayShowConsumption = true
    @AppStorage("stats.today.showBatteryLevel") private var todayShowBatteryLevel = true
    @AppStorage("stats.today.showBatteryCharge") private var todayShowBatteryCharge = true
    @AppStorage("stats.today.showBatteryDischarge") private var todayShowBatteryDischarge = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Period filter (sticky)
                VStack(spacing: 12) {
                    Picker("Period", selection: $viewModel.selectedPeriod) {
                        ForEach(StatisticsPeriod.allCases) { period in
                            Text(period.localizedName).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .controlSize(.large)
                    .padding(.horizontal)

                    // Custom date range + resolution
                    if viewModel.selectedPeriod == .custom {
                        VStack(spacing: 6) {
                            // Row 1: date range + export
                            HStack {
                                DatePicker(
                                    "From",
                                    selection: $viewModel.customStartDate,
                                    displayedComponents: .date
                                )
                                .labelsHidden()

                                Image(systemName: "arrow.right")
                                    .foregroundStyle(.secondary)

                                DatePicker(
                                    "To",
                                    selection: $viewModel.customEndDate,
                                    displayedComponents: .date
                                )
                                .labelsHidden()

                                Spacer()

                                exportButton
                            }

                            // Row 2: resolution picker
                            Picker("Resolution", selection: $viewModel.customResolution) {
                                ForEach(CustomResolution.allCases) { res in
                                    Text(res.localizedName).tag(res)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(.horizontal)
                    }

                    // Time navigation + export for the fixed periods
                    HStack(spacing: 12) {
                        timeNavigation
                        if viewModel.selectedPeriod != .custom {
                            exportButton
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 8)
                .padding(.bottom, 8)

                // Scrollable content
                ScrollView {
                    VStack(spacing: 16) {
                        statisticsContent
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: shareURLs)
            }
            .confirmationDialog("Export Format", isPresented: $showExportFormatPicker) {
                Button("CSV") { exportStatistics(format: .csv) }
                Button("Excel (.xlsx)") { exportStatistics(format: .xlsx) }
                Button("Cancel", role: .cancel) {}
            }
        }
        .onChange(of: viewModel.selectedPeriod) {
            viewModel.periodChanged()
        }
        .task(id: windowIdentity) {
            // Scrolling walks through windows quickly; settle first so a flick
            // does not fire a request per window passed.
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await viewModel.loadWindow()
            refreshChartData()
            guard !Task.isCancelled else { return }
            await viewModel.loadTotals()
        }
        .task(id: viewModel.selectedPeriod) {
            guard viewModel.selectedPeriod == .overall else { return }
            await viewModel.loadLifetimeStatistics()
        }
        .task {
            await viewModel.loadEarliestDate()
        }
    }

    private func refreshChartData() {
        intradayData.data = viewModel.intraday.marks(around: viewModel.window, paddingDays: 0)
        intradayBatteries = viewModel.intraday.batteryMarks(around: viewModel.window, paddingDays: 0)
        barMarks = viewModel.visibleBuckets
        visibleBars = viewModel.visibleBuckets
        futureShading = ChartFutureShading(window: viewModel.window)
    }

    /// Changes to this restart the loading task: the window moved, or the
    /// buckets it is cut into changed.
    private var windowIdentity: String {
        let window = viewModel.window
        return "\(viewModel.selectedPeriod.rawValue)|\(window.lowerBound.timeIntervalSince1970)|\(window.upperBound.timeIntervalSince1970)|\(viewModel.customResolution.rawValue)"
    }

    // MARK: - Time navigation

    @ViewBuilder
    private var timeNavigation: some View {
        if let navigator = viewModel.navigator {
            ChartTimeHeader(
                navigator: navigator,
                isLoading: viewModel.isLoading || viewModel.isLoadingTotals
            )
        } else {
            // Custom range: the pickers set how long the window is, these
            // buttons move it — one whole range per tap.
            HStack(spacing: 8) {
                Button {
                    withAnimation(.snappy) { viewModel.stepCustomRange(by: -1) }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .frame(width: 30, height: 30)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canStepCustomBack)
                .foregroundStyle(
                    viewModel.canStepCustomBack ? Color.primary : Color.secondary.opacity(0.35)
                )
                .accessibilityLabel("Previous period")

                HStack(spacing: 6) {
                    Text(viewModel.windowLabel)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    if viewModel.isLoading || viewModel.isLoadingTotals {
                        ProgressView()
                            .controlSize(.mini)
                    }
                }
                .frame(maxWidth: .infinity)

                Button {
                    withAnimation(.snappy) { viewModel.stepCustomRange(by: 1) }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .frame(width: 30, height: 30)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canStepCustomForward)
                .foregroundStyle(
                    viewModel.canStepCustomForward ? Color.primary : Color.secondary.opacity(0.35)
                )
                .accessibilityLabel("Next period")
            }
        }
    }

    /// Left/right swipe switches the period. Bound to a minimum distance well
    /// above the chart's own scrolling so the two do not fight.
    private var periodSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 50, coordinateSpace: .local)
            .onEnded { value in
                let horizontal = value.translation.width
                let vertical = value.translation.height
                guard abs(horizontal) > abs(vertical) else { return }

                let periods = StatisticsPeriod.allCases
                guard let index = periods.firstIndex(of: viewModel.selectedPeriod) else { return }

                if horizontal < 0, index < periods.count - 1 {
                    withAnimation { viewModel.selectedPeriod = periods[index + 1] }
                } else if horizontal > 0 {
                    if index > 0 {
                        withAnimation { viewModel.selectedPeriod = periods[index - 1] }
                    } else {
                        // At the today (first-period) boundary,
                        // the right-swipe leaves Statistics and
                        // jumps to the previous top-level tab
                        // per TopLevelTabOrder. Mirrors the
                        // swipe-back semantics of the other tabs.
                        let order = TopLevelTabOrder.tabs
                        if let i = order.firstIndex(of: .statistics), i > 0 {
                            withAnimation {
                                TabSelection.shared.selectedTab = order[i - 1]
                            }
                        }
                    }
                }
            }
    }

    // MARK: - Current period series toggles

    private var showProduction: Binding<Bool> {
        switch viewModel.selectedPeriod {
        case .week: return $weekShowProduction
        case .month: return $monthShowProduction
        case .year: return $yearShowProduction
        case .overall: return $overallShowProduction
        case .custom: return $customShowProduction
        default: return .constant(true)
        }
    }
    private var showConsumption: Binding<Bool> {
        switch viewModel.selectedPeriod {
        case .week: return $weekShowConsumption
        case .month: return $monthShowConsumption
        case .year: return $yearShowConsumption
        case .overall: return $overallShowConsumption
        case .custom: return $customShowConsumption
        default: return .constant(true)
        }
    }
    private var showImport: Binding<Bool> {
        switch viewModel.selectedPeriod {
        case .week: return $weekShowImport
        case .month: return $monthShowImport
        case .year: return $yearShowImport
        case .overall: return $overallShowImport
        case .custom: return $customShowImport
        default: return .constant(true)
        }
    }
    private var showExport: Binding<Bool> {
        switch viewModel.selectedPeriod {
        case .week: return $weekShowExport
        case .month: return $monthShowExport
        case .year: return $yearShowExport
        case .overall: return $overallShowExport
        case .custom: return $customShowExport
        default: return .constant(true)
        }
    }

    // MARK: - Export

    @ViewBuilder
    private var exportButton: some View {
        if viewModel.exportableData != nil {
            Button {
                showExportFormatPicker = true
            } label: {
                if isExporting {
                    ProgressView().controlSize(.mini)
                } else {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            .tint(.primary)
            .disabled(isExporting)
        }
    }

    private func exportStatistics(format: ExportFormat) {
        isExporting = true
        Task {
            defer { isExporting = false }
            do {
                let url: URL
                // High-resolution export: one timestamped row per interval.
                if let intervals = await viewModel.intervalDataForExport() {
                    url = try StatisticsExporter.exportIntervals(data: intervals, format: format)
                } else {
                    guard let data = viewModel.exportableData, !data.isEmpty else { return }
                    url = try StatisticsExporter.export(
                        data: data,
                        periodLabel: viewModel.selectedPeriod.rawValue,
                        format: format
                    )
                }
                shareURLs = [url]
                showShareSheet = true
            } catch {
                // Silently fail — file write errors are unlikely for temp directory
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var statisticsContent: some View {
        // Today: intraday area chart, scrollable day by day
        if viewModel.selectedPeriod == .today {
            todayContent
        }

        // Every other period: a bar chart of the buckets in the window
        if let bucket = viewModel.bucket {
            VStack(spacing: 8) {
                FilterableBarChart(
                    data: barMarks,
                    xUnit: bucket.calendarComponent,
                    xLabelFormat: xLabelFormat,
                    showProduction: showProduction,
                    showConsumption: showConsumption,
                    showImport: showImport,
                    showExport: showExport,
                    chartHeight: 200,
                    visibleData: visibleBars,
                    scrollConfig: barChartScrollConfig
                )
            }
            .padding(.horizontal)
        }

        // Overall: lifetime stats with eco meter
        if viewModel.selectedPeriod == .overall,
           let stats = viewModel.lifetimeStatistics
        {
            EcoMeterCard(totalProduction: stats.production ?? 0)
                .padding(.horizontal)
        }

        StatisticsEnergyCards(
            statistics: viewModel.windowStatistics,
            batteryCharged: viewModel.batteryCharged,
            batteryDischarged: viewModel.batteryDischarged,
            carCharged: viewModel.carCharged,
            heatpumpConsumed: viewModel.heatpumpConsumed,
            boilerConsumed: viewModel.boilerConsumed,
            isCurrentlyCharging: viewModel.isCurrentlyCharging,
            hasBattery: buildingState.overviewData.hasAnyBattery
                && viewModel.batteryFiguresAvailable,
            hasCarChargingStation: buildingState.overviewData.hasAnyCarChargingStation,
            gridImportOverride: viewModel.measuredGrid?.imported,
            gridExportOverride: viewModel.measuredGrid?.exported
        )
        // The charts own horizontal drags now, so period switching only
        // listens below them.
        .simultaneousGesture(periodSwipeGesture)

        if viewModel.auxTotalsUnavailable {
            Text(
                "Solar Manager reports car charging, heat pump and boiler consumption per device only — for ranges up to one year."
            )
            .font(.caption2)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
        }
    }

    /// The bar charts plot raw dates, so their scroll domain needs no
    /// time-zone shift — unlike the intraday chart below.
    private var barChartScrollConfig: ChartTimeScrollConfig? {
        viewModel.navigator?.scrollConfig()
    }

    private var xLabelFormat: XLabelFormat {
        switch viewModel.selectedPeriod {
        case .week: .weekday
        case .month: .dayOfMonth
        case .year: .monthNarrow
        case .overall: .year
        case .custom: viewModel.customResolution.chartXLabelFormat
        case .today: .dayOfMonth
        }
    }

    @ViewBuilder
    private var todayContent: some View {
        VStack(spacing: 8) {
            OverviewChart(
                consumption: intradayData,
                batteries: intradayBatteries,
                isSmall: true,
                showProduction: todayShowProduction,
                showConsumption: todayShowConsumption,
                showBatteryCharge: todayShowBatteryCharge,
                showBatteryDischange: todayShowBatteryDischarge,
                showBatteryPercentage: todayShowBatteryLevel,
                scrollConfig: viewModel.navigator?.scrollConfig(),
                yMaxOverride: todayYMax,
                futureShading: futureShading
            )
            .frame(height: 200)

            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    SeriesToggle(label: "Production", color: .yellow, isOn: $todayShowProduction)
                    SeriesToggle(label: "Consumption", color: .teal, isOn: $todayShowConsumption)
                }
                HStack(spacing: 6) {
                    SeriesToggle(label: "Battery %", color: .green, isOn: $todayShowBatteryLevel)
                    SeriesToggle(label: "Charged", color: .purple, isOn: $todayShowBatteryCharge)
                    SeriesToggle(label: "Discharged", color: .indigo, isOn: $todayShowBatteryDischarge)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    /// Peak of the visible day, so scrolling onto an overcast day does not
    /// squash its curve against a sunny neighbour's axis.
    private var todayYMax: Double? {
        let peak = viewModel.intraday.items(in: viewModel.window)
            .map { max($0.productionWatts, $0.consumptionWatts) / 1000 }
            .max()
        guard let peak, peak > 0.005 else { return nil }
        return peak * 1.1
    }

}

#Preview {
    StatisticsScreen()
        .environment(
            CurrentBuildingState.fake(
                overviewData: OverviewData.fake()
            )
        )
}
