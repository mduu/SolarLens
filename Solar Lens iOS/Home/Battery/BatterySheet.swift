import SwiftUI

struct BatterySheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.energyManager) var energyManager
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(CurrentBuildingState.self) var model: CurrentBuildingState

    @State var isLoading: Bool = false
    @State private var navigator = ChartTimeNavigator(page: .day)
    @State private var store = IntradayChartStore()

    /// The marks the chart draws. Held as one long-lived object, refreshed
    /// only after a load: handing Swift Charts a freshly built series on every
    /// render makes it re-anchor its scroll offset.
    @State private var chartData = MainData(data: [])
    @State private var chartBatteries: [BatteryHistory] = []
    @State private var futureShading: ChartFutureShading?

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

            VStack(spacing: 0) {
                ChartTimeHeader(navigator: navigator, isLoading: store.isLoading)
                    .padding(.horizontal)
                    .padding(.top, 8)

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
        .task(id: navigator.windowStart) {
            // Scrolling walks through days quickly; settle first so a flick
            // across a week does not fire a request per day passed.
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            await store.ensureLoaded(around: navigator.window)
            chartData.data = store.marks(around: navigator.window)
            chartBatteries = store.batteryMarks(around: navigator.window)
            futureShading = ChartFutureShading(window: navigator.window)
        }
        .task {
            await applyEarliestDate()
        }
    }

    // MARK: - Portrait Layout

    private var portraitContent: some View {
        VStack(spacing: 16) {
            batteryStatusCard

            batteryChartCard

            BatteryAdvantageSection(
                hasAnyBattery: model.overviewData.hasAnyBattery
            )

            let batteries = model.overviewData.devices.filter { $0.deviceType == .battery }
            if !batteries.isEmpty {
                BatteryDevicesCard(batteries: batteries)
            }
        }
        .padding()
    }

    // MARK: - Landscape Layout

    private var landscapeContent: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 16) {
                batteryChartCard
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 16) {
                batteryStatusCard

                BatteryAdvantageSection(
                    hasAnyBattery: model.overviewData.hasAnyBattery
                )

                let batteries = model.overviewData.devices.filter { $0.deviceType == .battery }
                if !batteries.isEmpty {
                    BatteryDevicesCard(batteries: batteries)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
    }

    // MARK: - Status card

    /// The live level, charge rate and forecast only mean anything while the
    /// chart shows today. Once the user scrolls back, the card switches to
    /// describing that day instead.
    private var batteryDaySummary: BatteryDaySummary? {
        guard !navigator.isAtPresent else { return nil }

        let samples = store.items(in: navigator.window)
        let levels = samples.compactMap(\.batteryLevel)
        guard let low = levels.min(), let high = levels.max(),
            let endOfDay = samples.last(where: { $0.batteryLevel != nil })?.batteryLevel
        else { return nil }

        return BatteryDaySummary(endOfDay: endOfDay, low: low, high: high)
    }

    @ViewBuilder
    private var batteryStatusCard: some View {
        if let batteryDaySummary {
            BatteryStatusCard(daySummary: batteryDaySummary)
        } else if navigator.isAtPresent {
            BatteryStatusCard(
                level: model.overviewData.currentBatteryLevel ?? 0,
                charging: model.overviewData.currentBatteryChargeRate ?? 0,
                forecastText: compactForecastText
            )
        }
    }

    // MARK: - Scrollable chart

    private var batteryChartCard: some View {
        BatteryTodayCard(
            mainData: chartData,
            batteryHistory: chartBatteries,
            window: navigator.window,
            windowLabel: navigator.windowLabel,
            scrollConfig: navigator.scrollConfig(),
            isLoading: store.isLoading,
            futureShading: futureShading
        )
    }

    /// Stops the user from scrolling back past the day the Solar Manager
    /// installation was registered — there is no data before that.
    private func applyEarliestDate() async {
        guard let info = try? await energyManager.fetchServerInfo(),
            let registered = info.registrationDate
        else { return }
        navigator.setEarliest(registered)
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
}

#Preview {
    NavigationView {
        BatterySheet()
            .environment(CurrentBuildingState.fake())
    }
}
