import SwiftUI

struct BatteryAdvantageCard: View {
    let mainData: MainData?
    let tariff: TariffV1Response?
    let tariffSettings: TariffSettingsV3Response?
    let todayConsumption: Double
    let todayProduction: Double
    let autarkyWithBattery: Double
    let selfConsumptionWithBattery: Double
    let hasAnyBattery: Bool

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

        let netSavings = TariffCalculator.batterySavings(
            data: mainData?.data ?? [],
            tariffSettings: tariffSettings,
            fallbackTariff: tariff
        )

        if hasAnyBattery {
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

                            if netSavings != 0 {
                                let currencyCode = CurrencyHelper.currencyCode
                                Text(verbatim: "≈ \(netSavings.formatted(.currency(code: currencyCode)))")
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
                            Text("Without battery: \(String(format: "%.1f%%", autarkyWithout))")
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
                            Text("Without battery: \(String(format: "%.1f%%", selfConsumptionWithout))")
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
}
