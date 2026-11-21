import SwiftUI

/// The home screen for the iPad and the Mac.
///
/// The iPhone's home screen answers "what is happening right now" and puts
/// everything else behind a tap. A larger window has room for the answers to
/// the next questions as well — how the day went, what is coming, what is
/// drawing power — so they sit beside the live tiles instead of behind them.
/// The tiles themselves are the same views the iPhone uses and react to a tap
/// the same way; only where their detail appears differs (see
/// `HomeDetailRouter`).
struct HomeDashboardLayout: View {
    @Environment(CurrentBuildingState.self) var buildingState: CurrentBuildingState
    @Environment(\.layoutWidth) private var layout
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @Binding var showError: Bool
    let solarDetailsData: SolarDetailsData?
    let onRefresh: () -> Void

    /// Owned by `HomeScreen`, which also hosts the pane it drives.
    @Environment(HomeDetailRouter.self) private var router
    @StateObject private var pinnedConfig = PinnedDevicesConfiguration()

    @State private var chartNavigator = ChartTimeNavigator(page: .day)
    @State private var chartStore = IntradayChartStore()

    @State private var showEfficiencySheet = false
    /// Width left for the tiles once the detail pane has taken its share.
    @State private var contentWidth: CGFloat = 0

    /// Two columns of cards need this much; below it they stack.
    private var usesTwoColumns: Bool { contentWidth >= 860 }

    var body: some View {
        VStack(spacing: 16) {
            HeaderView(onRefresh: onRefresh, showError: $showError)
                .padding(.horizontal, -16)

            nowContent
            // The tiles keep the iPhone's type sizes, which read as small
            // print on a 13" screen held at arm's length.
            .dynamicTypeSize(tileTypeSize)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { newValue in
            contentWidth = newValue
        }
        .onAppear {
            router.pinnedConfig = pinnedConfig
        }
        .sheet(isPresented: $showEfficiencySheet) {
            EfficiencySheet(hasAnyBattery: buildingState.overviewData.hasAnyBattery)
        }
    }

    private var tileTypeSize: DynamicTypeSize {
        guard layout == .wide else { return dynamicTypeSize }
        return max(dynamicTypeSize, .xLarge)
    }

    // MARK: - Now

    @ViewBuilder
    private var nowContent: some View {
        if usesTwoColumns {
            HStack(alignment: .top, spacing: 16) {
                VStack(spacing: 16) {
                    flowGrid
                    HStack(alignment: .top, spacing: 16) {
                        forecastCard
                        efficiencyCard
                    }
                    todayFiguresCard
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 16) {
                    dayChartCard
                        .frame(maxHeight: .infinity)
                    devicesCard
                }
                .frame(maxWidth: .infinity)
            }
            // The left column sets the height; the chart on the right grows
            // to match, so neither column ends in empty space.
            .fixedSize(horizontal: false, vertical: true)
        } else {
            // Forecast and efficiency before the chart: what the iPhone shows
            // at a glance stays above the fold; the chart is the detail.
            VStack(spacing: 16) {
                flowGrid
                HStack(alignment: .top, spacing: 16) {
                    forecastCard
                    efficiencyCard
                }
                dayChartCard
                todayFiguresCard
                devicesCard
            }
        }
    }

    private var flowGrid: some View {
        EnergyFlowGrid(showCharging: true, pinnedConfig: pinnedConfig)
            .padding(.vertical, 4)
    }

    // MARK: - Cards

    private var dayChartCard: some View {
        VStack(spacing: 8) {
            ChartTimeHeader(navigator: chartNavigator, isLoading: chartStore.isLoading)

            ChartView(navigator: chartNavigator, store: chartStore)
                .frame(minHeight: 400, maxHeight: .infinity)
        }
        .cardStyle()
    }

    @ViewBuilder
    private var forecastCard: some View {
        if let solarDetailsData {
            SolarForecastView(
                solarProductionMax: buildingState.overviewData.solarProductionMax,
                todaySolarProduction: solarDetailsData.todaySolarProduction,
                forecastToday: solarDetailsData.forecastToday,
                forecastTomorrow: solarDetailsData.forecastTomorrow,
                forecastDayAfterTomorrow: solarDetailsData.forecastDayAfterTomorrow
            )
        } else {
            ProgressView()
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .cardStyle()
        }
    }

    private var efficiencyCard: some View {
        Button {
            if !router.open(.efficiency) { showEfficiencySheet = true }
        } label: {
            EfficiencyGaugeView(
                todaySelfConsumptionRate: buildingState.overviewData.todaySelfConsumptionRate,
                todayAutarchyDegree: buildingState.overviewData.todayAutarchyDegree
            )
            .cardStyle()
            .cardDisclosure()
        }
        .buttonStyle(CardButtonStyle())
        .detailSelection(router.detail == .efficiency)
    }

    /// The day's totals. On the iPhone these hide in the small print under
    /// each tile's live value.
    private var todayFiguresCard: some View {
        let data = buildingState.overviewData

        return VStack(alignment: .leading, spacing: 12) {
            cardTitle("Today so far", systemImage: "calendar")

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 120), spacing: 12, alignment: .leading)],
                alignment: .leading,
                spacing: 12
            ) {
                figure("Produced", wattHours: data.todayProduction, color: .orange)
                figure("Consumed", wattHours: data.todayConsumption, color: .teal)
                figure(
                    "Imported",
                    wattHours: data.todayGridImported.map(Double.init),
                    color: .purple
                )
                figure("Exported", wattHours: Double(data.todayGridExported), color: .indigo)
                if data.hasAnyBattery {
                    figure("Charged", wattHours: data.todayBatteryCharged, color: .green)
                }
            }
        }
        .cardStyle()
    }

    private func figure(
        _ label: LocalizedStringKey, wattHours: Double?, color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 5) {
                Circle()
                    .fill(color)
                    .frame(width: 7, height: 7)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Text(
                wattHours.map { $0.formatWattHoursAsKiloWattsHours(widthUnit: true) } ?? "–"
            )
            .font(.headline)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
    }

    /// What is drawing power, biggest first.
    @ViewBuilder
    private var devicesCard: some View {
        let devices = buildingState.overviewData.devices
            .filter { $0.deviceType != .battery }
            .sorted { $0.currentPowerInWatts > $1.currentPowerInWatts }
            .prefix(6)

        if !devices.isEmpty {
            Button {
                router.pinnedConfig = pinnedConfig
                _ = router.open(.consumption)
            } label: {
                VStack(alignment: .leading, spacing: 10) {
                    cardTitle("Devices", systemImage: "powerplug.fill")

                    ForEach(Array(devices)) { device in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(device.currentPowerInWatts > 0 ? Color.teal : Color.secondary.opacity(0.35))
                                .frame(width: 8, height: 8)
                            Text(device.name)
                                .font(.subheadline)
                                .lineLimit(1)
                            Spacer(minLength: 8)
                            Text(verbatim: powerText(watts: device.currentPowerInWatts))
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(device.currentPowerInWatts > 0 ? .primary : .secondary)
                        }
                    }
                }
                .cardStyle()
                .contentShape(Rectangle())
            }
            .buttonStyle(CardButtonStyle())
            .disabled(!router.usesPane)
            .detailSelection(router.detail == .consumption)
        }
    }

    /// Watts below a kilowatt: "0.0 kW" for a laptop charger says nothing.
    private func powerText(watts: Int) -> String {
        if watts <= 0 { return "–" }
        if watts < 1000 { return "\(watts) W" }
        return "\((Double(watts) / 1000).localized(decimals: 1)) kW"
    }

    private func cardTitle(_ title: LocalizedStringKey, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

}

#Preview("Now") {
    ZStack {
        BackgroundView().ignoresSafeArea()
        LayoutWidthReader { _ in
            ScrollView {
                HomeDashboardLayout(
                    showError: .constant(false),
                    solarDetailsData: SolarDetailsData.fake(),
                    onRefresh: {}
                )
            }
        }
    }
    .environment(HomeDetailRouter())
    .environment(
        CurrentBuildingState.fake(
            overviewData: OverviewData.fake()
        )
    )
}
