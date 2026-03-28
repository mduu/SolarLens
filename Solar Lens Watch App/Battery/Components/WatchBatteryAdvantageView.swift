import SwiftUI

struct WatchBatteryAdvantageView: View {
    let mainData: MainData?
    let tariff: TariffV1Response?
    let todayConsumption: Double
    let todayProduction: Double
    let autarkyWithBattery: Double
    let selfConsumptionWithBattery: Double

    var body: some View {
        let totalDischarged = mainData?.data.reduce(0.0) { $0 + $1.batteryDischargedWh } ?? 0
        let totalCharged = mainData?.data.reduce(0.0) { $0 + $1.batteryChargedWh } ?? 0

        let autarkyWithout = todayConsumption > 0
            ? max(autarkyWithBattery - (totalDischarged / todayConsumption * 100), 0)
            : 0
        let autarkyImprovement = autarkyWithBattery - autarkyWithout

        let selfConsumptionWithout = todayProduction > 0
            ? max(selfConsumptionWithBattery - (totalCharged / todayProduction * 100), 0)
            : 0
        let selfConsumptionImprovement = selfConsumptionWithBattery - selfConsumptionWithout

        HStack(spacing: 0) {
            // Savings
            if let gridPrice = tariff?.highTariff ?? tariff?.singleTariff,
               gridPrice > 0
            {
                let currencyCode = Locale.current.currency?.identifier ?? "CHF"
                let importSaved = (totalDischarged / 1000) * (gridPrice / 100)
                let feedInPrice = tariff?.directMarketing ?? 0
                let exportLost = (totalCharged / 1000) * (feedInPrice / 100)
                let netSavings = importSaved - exportLost

                VStack(spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text(netSavings, format: .number.precision(.fractionLength(2)))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                        Text(currencyCode)
                            .font(.system(size: 8))
                            .foregroundStyle(.green.opacity(0.7))
                    }
                    Text("Saved")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }

            // Autarky
            VStack(spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text(String(format: "+%.0f", autarkyImprovement))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                    Text("%")
                        .font(.system(size: 8))
                        .foregroundStyle(.green.opacity(0.7))
                }
                Text("Autarky")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            // Self-consumption
            VStack(spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text(String(format: "+%.0f", selfConsumptionImprovement))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                    Text("%")
                        .font(.system(size: 8))
                        .foregroundStyle(.green.opacity(0.7))
                }
                Text("Self-cons.")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
        )
    }
}
