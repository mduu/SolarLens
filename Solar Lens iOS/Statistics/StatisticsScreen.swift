import Charts
import SwiftUI

struct StatisticsScreen: View {
    @Environment(CurrentBuildingState.self) var buildingState: CurrentBuildingState
    @State private var viewModel = StatisticsViewModel()

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

                    // Custom date range
                    if viewModel.selectedPeriod == .custom {
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

                            Button {
                                Task { await viewModel.fetch() }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                            }
                            .buttonStyle(.bordered)
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
        }
        .onChange(of: viewModel.selectedPeriod) {
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
        default: return .constant(true)
        }
    }
    private var showConsumption: Binding<Bool> {
        switch viewModel.selectedPeriod {
        case .week: return $weekShowConsumption
        case .month: return $monthShowConsumption
        case .year: return $yearShowConsumption
        case .overall: return $overallShowConsumption
        default: return .constant(true)
        }
    }
    private var showImport: Binding<Bool> {
        switch viewModel.selectedPeriod {
        case .week: return $weekShowImport
        case .month: return $monthShowImport
        case .year: return $yearShowImport
        case .overall: return $overallShowImport
        default: return .constant(true)
        }
    }
    private var showExport: Binding<Bool> {
        switch viewModel.selectedPeriod {
        case .week: return $weekShowExport
        case .month: return $monthShowExport
        case .year: return $yearShowExport
        case .overall: return $overallShowExport
        default: return .constant(true)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var statisticsContent: some View {
        // Today: area chart + pie charts stacked vertically
        if viewModel.selectedPeriod == .today {
            todayContent
        }

        // Week / Month / Custom: daily bar chart with toggles
        if let dailyStats = viewModel.dailyStats,
           [.week, .month, .custom].contains(viewModel.selectedPeriod)
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
            .padding(.horizontal)
        }

        // Energy info row (car charging + battery) — not on today, handled in todayContent
        if ![.today, .overall].contains(viewModel.selectedPeriod) {
            EnergyInfoRow(
                carCharged: viewModel.carCharged,
                batteryCharged: viewModel.batteryCharged,
                batteryDischarged: viewModel.batteryDischarged,
                isCurrentlyCharging: viewModel.isCurrentlyCharging,
                useMWh: [.year, .overall].contains(viewModel.selectedPeriod),
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
            statisticsDonutCharts(
                for: stats,
                useMWh: [.year, .overall].contains(viewModel.selectedPeriod)
            )
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
    private func statisticsDonutCharts(for stats: Statistics, useMWh: Bool = false) -> some View {
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
                total: consumption,
                useMWh: useMWh
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
                total: production,
                useMWh: useMWh
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
