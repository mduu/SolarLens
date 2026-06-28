import SwiftUI

struct BatteryAdvantageCard: View {
    let mainData: MainData?
    let tariff: TariffV1Response?
    let tariffSettings: TariffSettingsV3Response?
    var dynamicTariff: DynamicTariff? = nil
    let consumption: Double
    let production: Double
    let autarkyWithBattery: Double
    let selfConsumptionWithBattery: Double
    let hasAnyBattery: Bool

    var body: some View {
        let totalDischarged = mainData?.data.reduce(0.0) { $0 + $1.batteryDischargedWh } ?? 0
        let totalCharged = mainData?.data.reduce(0.0) { $0 + $1.batteryChargedWh } ?? 0

        let autarkyWithout = consumption > 0
            ? max(autarkyWithBattery - (totalDischarged / consumption * 100), 0)
            : 0
        let autarkyImprovement = autarkyWithBattery - autarkyWithout

        let selfConsumptionWithout = production > 0
            ? max(selfConsumptionWithBattery - (totalCharged / production * 100), 0)
            : 0
        let selfConsumptionImprovement = selfConsumptionWithBattery - selfConsumptionWithout

        let avoidedImportValue = TariffCalculator.avoidedImportValue(
            data: mainData?.data ?? [],
            tariffSettings: tariffSettings,
            fallbackTariff: tariff,
            dynamicImport: dynamicTariff
        )
        let forgoneExportValue = TariffCalculator.forgoneExportRevenue(
            data: mainData?.data ?? [],
            tariffSettings: tariffSettings,
            fallbackTariff: tariff
        )
        let netBenefit = avoidedImportValue - forgoneExportValue

        // Effective (energy-weighted) rates actually applied, surfaced in the
        // footnote so the basis is transparent and any mis-read is visible.
        let dischargedKwh = totalDischarged / 1000
        let chargedKwh = totalCharged / 1000
        let effImportRate = dischargedKwh > 0 ? avoidedImportValue / dischargedKwh : 0
        let effFeedRate = chargedKwh > 0 ? forgoneExportValue / chargedKwh : 0

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

                // Money the battery added (net = import avoided − feed-in forgone)
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(.green.opacity(0.12))
                            .frame(width: 40, height: 40)
                        Image(systemName: "francsign.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.green)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Money saved")
                            .font(.caption)
                            .foregroundStyle(.primary.opacity(0.7))
                        Text(verbatim: netBenefit.formatted(.currency(code: CurrencyHelper.currencyCode)))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                    }

                    Spacer()
                }

                // Breakdown: import you avoided buying + feed-in you forwent
                HStack(alignment: .top, spacing: 0) {
                    moneyBreakdown(
                        title: "Grid import avoided",
                        energyWh: totalDischarged,
                        value: avoidedImportValue,
                        positive: true
                    )
                    Spacer()
                    moneyBreakdown(
                        title: "Feed-in forgone",
                        energyWh: totalCharged,
                        value: forgoneExportValue,
                        positive: false
                    )
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

                TariffRatesFootnote(importRate: effImportRate, feedInRate: effFeedRate)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
        }
    }

    @ViewBuilder
    private func moneyBreakdown(
        title: LocalizedStringKey,
        energyWh: Double,
        value: Double,
        positive: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(energyWh.formatWattHoursAsKiloWattsHours(widthUnit: true))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.primary.opacity(0.8))
            Text(verbatim: "\(positive ? "+" : "−")\(value.formatted(.currency(code: CurrencyHelper.currencyCode)))")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(positive ? .green : .secondary)
        }
    }
}
