import Charts
import SwiftUI

struct StatisticsScreen: View {
    @Environment(CurrentBuildingState.self) var buildingState: CurrentBuildingState
    @State private var viewModel = StatisticsViewModel()
    @State private var shareURLs: [URL] = []
    @State private var showShareSheet = false
    @State private var showExportFormatPicker = false

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

                                if exportableData != nil {
                                    Button {
                                        showExportFormatPicker = true
                                    } label: {
                                        Image(systemName: "square.and.arrow.up")
                                    }
                                    .tint(.primary)
                                }
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

                    // Export button for non-custom periods
                    if viewModel.selectedPeriod != .custom, exportableData != nil {
                        HStack {
                            Spacer()
                            Button {
                                showExportFormatPicker = true
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                            }
                            .tint(.primary)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 8)

                // Scrollable content
                ScrollView {
                    VStack(spacing: 16) {
                        if viewModel.isLoading {
                            ProgressView()
                                .padding(.top, 40)
                        } else {
                            statisticsContent
                        }
                    }
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 50, coordinateSpace: .local)
                        .onEnded { value in
                            let horizontal = value.translation.width
                            let vertical = value.translation.height
                            guard abs(horizontal) > abs(vertical) else { return }

                            let periods = StatisticsPeriod.allCases
                            guard let index = periods.firstIndex(of: viewModel.selectedPeriod) else { return }

                            if horizontal < 0, index < periods.count - 1 {
                                withAnimation { viewModel.selectedPeriod = periods[index + 1] }
                            } else if horizontal > 0, index > 0 {
                                withAnimation { viewModel.selectedPeriod = periods[index - 1] }
                            }
                        }
                )
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
            Task { await viewModel.fetch() }
        }
        .onChange(of: viewModel.customStartDate) {
            guard viewModel.selectedPeriod == .custom else { return }
            Task { await viewModel.fetch() }
        }
        .onChange(of: viewModel.customEndDate) {
            guard viewModel.selectedPeriod == .custom else { return }
            Task { await viewModel.fetch() }
        }
        .onChange(of: viewModel.customResolution) {
            guard viewModel.selectedPeriod == .custom else { return }
            Task { await viewModel.fetch() }
        }
        .task {
            await viewModel.fetch()
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

    /// Returns the exportable data for the current period, if any.
    private var exportableData: [DayStatistic]? {
        switch viewModel.selectedPeriod {
        case .week, .month:
            return viewModel.dailyStats
        case .custom:
            return viewModel.customStats
        case .year:
            return viewModel.monthlyStats
        case .overall:
            return viewModel.yearlyStats
        case .today:
            return nil
        }
    }

    private func exportStatistics(format: ExportFormat) {
        guard let data = exportableData, !data.isEmpty else { return }
        do {
            let url = try StatisticsExporter.export(
                data: data,
                periodLabel: viewModel.selectedPeriod.rawValue,
                format: format
            )
            shareURLs = [url]
            showShareSheet = true
        } catch {
            // Silently fail — file write errors are unlikely for temp directory
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var statisticsContent: some View {
        // Today: area chart + pie charts stacked vertically
        if viewModel.selectedPeriod == .today {
            todayContent
        }

        // Week / Month: daily bar chart with toggles
        if let dailyStats = viewModel.dailyStats,
           [.week, .month].contains(viewModel.selectedPeriod)
        {
            VStack(spacing: 8) {
                FilterableBarChart(
                    data: dailyStats,
                    xUnit: .day,
                    xLabelFormat: viewModel.selectedPeriod == .week ? .weekday : .dayOfMonth,
                    showProduction: showProduction,
                    showConsumption: showConsumption,
                    showImport: showImport,
                    showExport: showExport,
                    chartHeight: 200
                )
            }
            .padding(.horizontal)
        }

        // Custom: bar chart with user-selected resolution
        if let customStats = viewModel.customStats,
           viewModel.selectedPeriod == .custom
        {
            VStack(spacing: 8) {
                FilterableBarChart(
                    data: customStats,
                    xUnit: viewModel.customResolution.chartXUnit,
                    xLabelFormat: viewModel.customResolution.chartXLabelFormat,
                    showProduction: showProduction,
                    showConsumption: showConsumption,
                    showImport: showImport,
                    showExport: showExport,
                    chartHeight: 200
                )
            }
            .padding(.horizontal)
        }

        // Year: monthly bar chart with toggles
        if let monthlyStats = viewModel.monthlyStats,
           viewModel.selectedPeriod == .year
        {
            VStack(spacing: 8) {
                FilterableBarChart(
                    data: monthlyStats,
                    xUnit: .month,
                    xLabelFormat: .monthNarrow,
                    showProduction: showProduction,
                    showConsumption: showConsumption,
                    showImport: showImport,
                    showExport: showExport
                )
            }
            .padding(.horizontal)
        }

        // Overall: yearly bar chart
        if let yearlyStats = viewModel.yearlyStats,
           viewModel.selectedPeriod == .overall
        {
            VStack(spacing: 8) {
                FilterableBarChart(
                    data: yearlyStats,
                    xUnit: .year,
                    xLabelFormat: .year,
                    showProduction: showProduction,
                    showConsumption: showConsumption,
                    showImport: showImport,
                    showExport: showExport,
                    chartHeight: 200
                )
            }
            .padding(.horizontal)
        }

        // Energy info row (car charging + battery) — not on today, handled in todayContent
        if ![.today, .overall].contains(viewModel.selectedPeriod) {
            EnergyInfoRow(
                carCharged: viewModel.carCharged,
                batteryCharged: viewModel.batteryCharged,
                batteryDischarged: viewModel.batteryDischarged,
                isCurrentlyCharging: viewModel.isCurrentlyCharging,
                hasCarChargingStation: buildingState.overviewData.hasAnyCarChargingStation,
                hasBattery: buildingState.overviewData.hasAnyBattery
            )
        }

        // Overall: lifetime stats with eco meter
        if viewModel.selectedPeriod == .overall,
           let stats = viewModel.overallStatistics
        {
            EcoMeterCard(totalProduction: stats.production ?? 0)
                .padding(.horizontal)
        }

        // Donut charts (not on today — today uses live overview data)
        if viewModel.selectedPeriod != .today,
           let stats = viewModel.selectedPeriod == .overall
            ? viewModel.overallStatistics
            : viewModel.statistics
        {
            statisticsDonutCharts(for: stats)
        }
    }

    @ViewBuilder
    private var todayContent: some View {
        if let todayData = viewModel.todayData {
            VStack(spacing: 8) {
                OverviewChart(
                    consumption: todayData,
                    batteries: viewModel.batteryHistory ?? [],
                    isSmall: true,
                    showProduction: todayShowProduction,
                    showConsumption: todayShowConsumption,
                    showBatteryCharge: todayShowBatteryCharge,
                    showBatteryDischange: todayShowBatteryDischarge,
                    showBatteryPercentage: todayShowBatteryLevel
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

        EnergyInfoRow(
            carCharged: viewModel.carCharged,
            batteryCharged: viewModel.batteryCharged,
            batteryDischarged: viewModel.batteryDischarged,
            isCurrentlyCharging: viewModel.isCurrentlyCharging,
            hasCarChargingStation: buildingState.overviewData.hasAnyCarChargingStation,
            hasBattery: buildingState.overviewData.hasAnyBattery
        )

        let overview = buildingState.overviewData
        let todayStats = Statistics(
            consumption: overview.todayConsumption,
            production: overview.todayProduction,
            selfConsumption: overview.todaySelfConsumption,
            selfConsumptionRate: overview.todaySelfConsumptionRate,
            autarchyDegree: overview.todayAutarchyDegree
        )

        statisticsDonutCharts(for: todayStats)
    }

    @ViewBuilder
    private func statisticsDonutCharts(for stats: Statistics) -> some View {
        let consumption = stats.consumption ?? 0
        let production = stats.production ?? 0
        let selfConsumption = stats.selfConsumption ?? 0
        let gridImport = max(0, consumption - selfConsumption)
        let gridExport = max(0, production - selfConsumption)
        let autarky = stats.autarchyDegree ?? 0
        let selfConsumptionRate = stats.selfConsumptionRate ?? 0

        // Consumption donut
        VStack(spacing: 10) {
            Text("Consumption")
                .font(.headline)
                .foregroundStyle(.orange)
                .padding(.top, 8)

            StatisticsDonutChart(
                leftLabel: "Solar",
                leftValue: selfConsumption,
                leftColor: .orange,
                leftSubtitle: "\(autarky, specifier: "%.0f")% Autarky",
                rightLabel: "Grid",
                rightValue: gridImport,
                rightColor: Color(red: 1.0, green: 0.3, blue: 0.15),
                rightSubtitle: "\(100 - autarky, specifier: "%.0f")%",
                total: consumption
            )
        }
        .padding(.horizontal, 32)

        // Production donut
        VStack(spacing: 10) {
            Text("Production")
                .font(.headline)
                .foregroundStyle(.indigo)
                .padding(.top, 8)

            StatisticsDonutChart(
                leftLabel: "Self consumption",
                leftValue: selfConsumption,
                leftColor: .indigo,
                leftSubtitle: "\(selfConsumptionRate, specifier: "%.0f")%",
                rightLabel: "Exported",
                rightValue: gridExport,
                rightColor: .purple,
                rightSubtitle: "\(100 - selfConsumptionRate, specifier: "%.0f")%",
                total: production
            )
        }
        .padding(.horizontal, 32)
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
