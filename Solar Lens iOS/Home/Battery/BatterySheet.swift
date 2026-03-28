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
    @State private var tariffSettings: TariffSettingsV3Response?

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
            BatteryStatusCard(
                level: model.overviewData.currentBatteryLevel ?? 0,
                charging: model.overviewData.currentBatteryChargeRate ?? 0,
                forecastText: compactForecastText
            )

            BatteryTodayCard(
                mainData: mainData,
                batteryHistory: batteryHistory
            )

            BatteryAdvantageCard(
                mainData: mainData,
                tariff: tariff,
                tariffSettings: tariffSettings,
                todayConsumption: model.overviewData.todayConsumption ?? 0,
                todayProduction: model.overviewData.todayProduction ?? 0,
                autarkyWithBattery: model.overviewData.todayAutarchyDegree ?? 0,
                selfConsumptionWithBattery: model.overviewData.todaySelfConsumptionRate ?? 0,
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
                BatteryTodayCard(
                    mainData: mainData,
                    batteryHistory: batteryHistory
                )
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 16) {
                BatteryStatusCard(
                    level: model.overviewData.currentBatteryLevel ?? 0,
                    charging: model.overviewData.currentBatteryChargeRate ?? 0,
                    forecastText: compactForecastText
                )

                BatteryAdvantageCard(
                    mainData: mainData,
                    tariff: tariff,
                    tariffSettings: tariffSettings,
                    todayConsumption: model.overviewData.todayConsumption ?? 0,
                    todayProduction: model.overviewData.todayProduction ?? 0,
                    autarkyWithBattery: model.overviewData.todayAutarchyDegree ?? 0,
                    selfConsumptionWithBattery: model.overviewData.todaySelfConsumptionRate ?? 0,
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

    private func fetchTodayData() async {
        async let mainDataTask = try? energyManager.fetchMainData(
            from: Date.todayStartOfDay(),
            to: Date.todayEndOfDay()
        )
        async let batteryHistoryTask = try? energyManager.fetchTodaysBatteryHistory()
        async let tariffTask = try? energyManager.fetchTariff()
        async let tariffSettingsTask = try? energyManager.fetchDetailedTariffs()

        let (fetchedMainData, fetchedBatteryHistory, fetchedTariff, fetchedSettings) =
            await (mainDataTask, batteryHistoryTask, tariffTask, tariffSettingsTask)
        self.mainData = fetchedMainData
        self.batteryHistory = fetchedBatteryHistory
        self.tariff = fetchedTariff
        self.tariffSettings = fetchedSettings
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
