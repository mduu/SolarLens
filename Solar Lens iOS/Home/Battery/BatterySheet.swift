import Charts
import SwiftUI

struct BatterySheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.energyManager) var energyManager
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(CurrentBuildingState.self) var model: CurrentBuildingState

    @State var isLoading: Bool = false
    @State private var mainData: MainData?
    @State private var batteryHistory: [BatteryHistory]?
    @State private var tariff: TariffV1Response?

    private static let maxForecastDuration: TimeInterval = 24 * 3600
    private let forecastFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
        formatter.zeroFormattingBehavior = .pad
        formatter.collapsesLargestUnit = true
        return formatter
    }()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(red: 0.06, green: 0.08, blue: 0.06), Color(red: 0.05, green: 0.05, blue: 0.05)]
                    : [Color(red: 0.94, green: 0.98, blue: 0.94), .white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                if model.overviewData.currentBatteryLevel != nil
                    || model.overviewData.currentBatteryChargeRate != nil
                {
                    if !model.overviewData.isStaleData {
                        if verticalSizeClass == .compact {
                            landscapeContent
                        } else {
                            portraitContent
                        }
                    } else {
                        Text("Stale data!")
                            .foregroundColor(.red)
                            .padding()
                    }
                } else {
                    Text("No battery data present!")
                        .font(.footnote)
                        .padding()
                }
            }

            if isLoading {
                ProgressView()
            }
        }
        .navigationTitle("Battery")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundColor(.green)
                }
            }
        }
        .task {
            await fetchTodayData()
        }
    }

    // MARK: - Portrait Layout

    private var portraitContent: some View {
        VStack(spacing: 16) {
            batteryStatusCard
            batteryTodayCard
            batteryAdvantageCard

            let batteries = model.overviewData.devices.filter { $0.deviceType == .battery }
            if !batteries.isEmpty {
                batteryDevicesCard(batteries: batteries)
            }
        }
        .padding()
    }

    // MARK: - Landscape Layout

    private var landscapeContent: some View {
        HStack(alignment: .top, spacing: 16) {
            // Left column: Today chart
            VStack(spacing: 16) {
                batteryTodayCard
            }
            .frame(maxWidth: .infinity)

            // Right column: Status + Advantage + Devices
            VStack(spacing: 16) {
                batteryStatusCard
                batteryAdvantageCard

                let batteries = model.overviewData.devices.filter { $0.deviceType == .battery }
                if !batteries.isEmpty {
                    batteryDevicesCard(batteries: batteries)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
    }

    private func fetchTodayData() async {
        async let mainDataTask = try? energyManager.fetchMainData(
            from: Date.todayStartOfDay(),
            to: Date.todayEndOfDay()
        )
        async let batteryHistoryTask = try? energyManager.fetchTodaysBatteryHistory()
        async let tariffTask = try? energyManager.fetchTariff()

        let (fetchedMainData, fetchedBatteryHistory, fetchedTariff) = await (mainDataTask, batteryHistoryTask, tariffTask)
        self.mainData = fetchedMainData
        self.batteryHistory = fetchedBatteryHistory
        self.tariff = fetchedTariff
    }

    // MARK: - Battery Status Card

    @ViewBuilder
    private var batteryStatusCard: some View {
        let level = model.overviewData.currentBatteryLevel ?? 0
        let charging = model.overviewData.currentBatteryChargeRate ?? 0
        let batteryColor = batteryAccentColor(level: level)

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "battery.100percent")
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.7))
                Text("Battery")
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.7))
            }

            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(batteryColor.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: batteryIconName(level: level, charging: charging))
                        .font(.title3)
                        .foregroundStyle(batteryColor)
                        .symbolEffect(
                            .pulse.wholeSymbol,
                            options: .repeat(.continuous),
                            isActive: charging > 0
                        )
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Text("\(level)%")
                            .font(.headline)
                            .fontWeight(.bold)

                        if charging != 0 {
                            HStack(spacing: 4) {
                                Image(systemName: charging > 0 ? "arrow.up" : "arrow.down")
                                    .font(.caption)
                                    .foregroundStyle(charging > 0 ? .green : .orange)
                                Text(abs(charging).formatWattsAsWattsKiloWatts(widthUnit: true))
                                    .font(.subheadline)
                                    .foregroundStyle(.primary.opacity(0.7))
                            }
                        }
                    }

                    BatterySheetBar(level: level, color: batteryColor)

                    if let forecastText = compactForecastText {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                                .foregroundStyle(.primary.opacity(0.7))
                            Text(forecastText)
                                .font(.caption2)
                                .foregroundStyle(.primary.opacity(0.7))
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Battery Devices Card

    @ViewBuilder
    private func batteryDevicesCard(batteries: [Device]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.7))
                Text("Devices")
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.7))
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                ForEach(batteries) { battery in
                    BatteryView(battery: battery)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Today Card

    @ViewBuilder
    private var batteryTodayCard: some View {
        let totalCharged = mainData?.data.reduce(0.0) { $0 + $1.batteryChargedWh } ?? 0
        let totalDischarged = mainData?.data.reduce(0.0) { $0 + $1.batteryDischargedWh } ?? 0

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.7))
                Text("Today")
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.7))
            }

            // Totals
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.caption)
                        .foregroundStyle(.purple)
                    Text("Charged:")
                        .font(.caption)
                        .foregroundStyle(.primary.opacity(0.7))
                    Text(totalCharged.formatWattHoursAsKiloWattsHours(widthUnit: true))
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.caption)
                        .foregroundStyle(.indigo)
                    Text("Discharged:")
                        .font(.caption)
                        .foregroundStyle(.primary.opacity(0.7))
                    Text(totalDischarged.formatWattHoursAsKiloWattsHours(widthUnit: true))
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                Spacer()
            }

            // Chart
            if let mainData, let batteryHistory, !batteryHistory.isEmpty {
                let maxkW = batteryHistory
                    .flatMap { $0.items }
                    .map { max($0.averagePowerChargedW, $0.averagePowerDischargedW) / 1000 }
                    .max() ?? 2.0

                Chart {
                    BatterySeries(
                        batteries: batteryHistory,
                        isAccent: false,
                        batteryConsumptionLabel: String(localized: "Discharged"),
                        batteryChargedLabel: String(localized: "Charged")
                    )

                    if mainData.data.contains(where: { $0.batteryLevel != nil }) {
                        BatteryLevelSeries(
                            data: mainData.data,
                            maxY: max(maxkW * 1.1, 0.5),
                            isAccent: false,
                            batteryLabel: String(localized: "Level")
                        )
                    }
                }
                .chartYScale(domain: 0...max(maxkW * 1.1, 0.5))
                .chartYAxis {
                    AxisMarks(preset: .automatic) { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .chartYAxisLabel("kW")
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisValueLabel(
                            format: .dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)
                        )
                    }
                }
                .chartLegend(.visible)
                .chartLegend(spacing: 4)
                .chartForegroundStyleScale([
                    String(localized: "Discharged"): Color.indigo,
                    String(localized: "Charged"): Color.purple,
                    String(localized: "Level"): SerieColors.batteryLevelColor(useAlternativeColors: false),
                ])
                .frame(height: 180)
            } else if mainData == nil {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Battery Advantage Card

    @ViewBuilder
    private var batteryAdvantageCard: some View {
        let totalDischarged = mainData?.data.reduce(0.0) { $0 + $1.batteryDischargedWh } ?? 0
        let totalCharged = mainData?.data.reduce(0.0) { $0 + $1.batteryChargedWh } ?? 0
        let todayConsumption = model.overviewData.todayConsumption ?? 0
        let todayProduction = model.overviewData.todayProduction ?? 0

        // Without battery: all discharged energy would have been grid import
        // Without battery: all charged energy (from solar) would have been exported
        let autarkyWithBattery = model.overviewData.todayAutarchyDegree ?? 0
        let selfConsumptionWithBattery = model.overviewData.todaySelfConsumptionRate ?? 0

        // Autarky without battery: remove discharged energy from self-consumed
        let autarkyWithout = todayConsumption > 0
            ? max(autarkyWithBattery - (totalDischarged / todayConsumption * 100), 0)
            : 0
        let autarkyImprovement = autarkyWithBattery - autarkyWithout

        // Self-consumption without battery: remove charged energy from self-consumed
        let selfConsumptionWithout = todayProduction > 0
            ? max(selfConsumptionWithBattery - (totalCharged / todayProduction * 100), 0)
            : 0
        let selfConsumptionImprovement = selfConsumptionWithBattery - selfConsumptionWithout

        if model.overviewData.hasAnyBattery {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.shield")
                        .font(.caption)
                        .foregroundStyle(.primary.opacity(0.7))
                    Text("Battery Advantage")
                        .font(.caption)
                        .foregroundStyle(.primary.opacity(0.7))
                }

                // Grid import avoided + savings
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(.green.opacity(0.12))
                            .frame(width: 40, height: 40)
                        Image(systemName: "arrow.down.left.circle")
                            .font(.body)
                            .foregroundStyle(.green)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Grid import avoided")
                            .font(.caption)
                            .foregroundStyle(.primary.opacity(0.7))
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(totalDischarged.formatWattHoursAsKiloWattsHours(widthUnit: true))
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            if let gridPrice = tariff?.highTariff ?? tariff?.singleTariff,
                               gridPrice > 0
                            {
                                let currencyCode = Locale.current.currency?.identifier ?? "EUR"
                                // Tariff prices are in Rappen/cents, convert to main currency unit
                                let importSaved = (totalDischarged / 1000) * (gridPrice / 100)
                                let feedInPrice = tariff?.directMarketing ?? 0
                                let exportLost = (totalCharged / 1000) * (feedInPrice / 100)
                                let netSavings = importSaved - exportLost

                                let formatted = netSavings.formatted(
                                    .currency(code: currencyCode)
                                )
                                Text(verbatim: "≈ \(formatted)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.green)
                            }
                        }
                    }

                    Spacer()
                }

                Divider()

                // Autarky improvement
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Autarky")
                            .font(.caption)
                            .foregroundStyle(.primary.opacity(0.7))

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            if autarkyImprovement > 0.1 {
                                Text(String(format: "+%.1f%%", autarkyImprovement))
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.green)
                            }

                            Text(String(format: "%.1f%%", autarkyWithBattery))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary.opacity(0.7))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill(.secondary.opacity(0.12))
                                )
                        }

                        if autarkyImprovement > 0.1 {
                            Text(String(format: "Without battery: %.1f%%", autarkyWithout))
                                .font(.caption2)
                                .foregroundStyle(.primary.opacity(0.5))
                        }
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Self-consumption")
                            .font(.caption)
                            .foregroundStyle(.primary.opacity(0.7))

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            if selfConsumptionImprovement > 0.1 {
                                Text(String(format: "+%.1f%%", selfConsumptionImprovement))
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.green)
                            }

                            Text(String(format: "%.1f%%", selfConsumptionWithBattery))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary.opacity(0.7))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill(.secondary.opacity(0.12))
                                )
                        }

                        if selfConsumptionImprovement > 0.1 {
                            Text(String(format: "Without battery: %.1f%%", selfConsumptionWithout))
                                .font(.caption2)
                                .foregroundStyle(.primary.opacity(0.5))
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
        }
    }

    // MARK: - Forecast

    private var compactForecastText: String? {
        guard let forecast = model.overviewData.getBatteryForecast() else { return nil }

        if forecast.isCharging,
           let duration = forecast.durationUntilFullyCharged,
           duration <= Self.maxForecastDuration,
           let time = forecast.timeWhenFullyCharged
        {
            let durationStr = forecastFormatter.string(from: duration) ?? ""
            return String(localized: "Full in \(durationStr) at \(time.formatted(date: .omitted, time: .shortened))")
        }

        if forecast.isDischarging,
           let duration = forecast.durationUntilDischarged,
           duration <= Self.maxForecastDuration,
           let time = forecast.timeWhenDischarged
        {
            let durationStr = forecastFormatter.string(from: duration) ?? ""
            return String(localized: "Empty in \(durationStr) at \(time.formatted(date: .omitted, time: .shortened))")
        }

        return nil
    }

    // MARK: - Helpers

    private func batteryAccentColor(level: Int) -> Color {
        if level > 10 { return .green }
        if level > 6 { return .orange }
        return .red
    }

    private func batteryIconName(level: Int, charging: Int) -> String {
        if charging > 0 { return "battery.100percent.bolt" }
        if level >= 95 { return "battery.100percent" }
        if level >= 70 { return "battery.75percent" }
        if level >= 50 { return "battery.50percent" }
        if level >= 10 { return "battery.25percent" }
        return "battery.0percent"
    }
}

// MARK: - Battery Bar (full-width, matches home screen style)

private struct BatterySheetBar: View {
    let level: Int
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 4)
                    .fill(color.opacity(0.15))

                // Fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.6), color],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * CGFloat(min(level, 100)) / 100)
            }
        }
        .frame(height: 10)
    }
}

#Preview {
    NavigationView {
        BatterySheet()
            .environment(CurrentBuildingState.fake())
    }
}
