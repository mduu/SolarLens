import SwiftUI

/// Wraps `BatteryAdvantageCard` with a period selector (today / week / month /
/// year) so battery owners can see savings, added autarky, and added
/// self-consumption over a chosen period rather than only today. The selected
/// period is persisted.
struct BatteryAdvantageSection: View {
    let hasAnyBattery: Bool

    @State private var viewModel = BatteryAdvantageViewModel()
    @AppStorage("battery.advantage.period") private var storedPeriod: String = EfficiencyPeriod.today.rawValue

    /// Periods offered for the battery advantage report.
    private let periods: [EfficiencyPeriod] = [.today, .days7, .days30, .days365]

    @State private var period: EfficiencyPeriod = .today

    var body: some View {
        VStack(spacing: 10) {
            Picker("Period", selection: $period) {
                ForEach(periods) { period in
                    Text(period.localizedName).tag(period)
                }
            }
            .pickerStyle(.segmented)

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
            } else {
                BatteryAdvantageCard(
                    mainData: viewModel.mainData,
                    tariff: viewModel.tariff,
                    tariffSettings: viewModel.tariffSettings,
                    dynamicTariff: viewModel.dynamicTariff,
                    consumption: viewModel.consumptionWh,
                    production: viewModel.productionWh,
                    autarkyWithBattery: viewModel.autarkyPercent,
                    selfConsumptionWithBattery: viewModel.selfConsumptionPercent,
                    hasAnyBattery: hasAnyBattery
                )
            }
        }
        .onAppear {
            if let stored = EfficiencyPeriod(rawValue: storedPeriod), periods.contains(stored) {
                period = stored
            }
        }
        .onChange(of: period) {
            storedPeriod = period.rawValue
            Task { await viewModel.fetch(period: period) }
        }
        .task {
            await viewModel.fetch(period: period)
        }
    }
}
