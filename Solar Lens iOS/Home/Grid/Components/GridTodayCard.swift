import Charts
import SwiftUI

struct GridTodayCard: View {
    let mainData: MainData?
    let tariffSettings: TariffSettingsV3Response?
    let fallbackTariff: TariffV1Response?

    @Environment(\.locale) private var locale

    private func localizedString(_ key: String) -> String {
        let bundle = Bundle.main
        if let path = bundle.path(forResource: locale.language.languageCode?.identifier, ofType: "lproj"),
           let locBundle = Bundle(path: path) {
            return NSLocalizedString(key, bundle: locBundle, comment: "")
        }
        return String(localized: String.LocalizationValue(key))
    }

    var body: some View {
        let data = mainData?.data ?? []
        let totalImport = data.reduce(0.0) { $0 + $1.importedOverTimeWhatthours }
        let totalExport = data.reduce(0.0) { $0 + $1.exportedOverTimeWhatthours }
        let importCost = TariffCalculator.gridImportCost(
            data: data, tariffSettings: tariffSettings, fallbackTariff: fallbackTariff)
        let exportRevenue = TariffCalculator.gridExportRevenue(
            data: data, tariffSettings: tariffSettings, fallbackTariff: fallbackTariff)
        let netBalance = exportRevenue - importCost
        let currencyCode = CurrencyHelper.currencyCode

        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 4) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.7))
                Text("Today")
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.7))
            }

            // Import / Export / Balance row
            HStack(spacing: 0) {
                // Import
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.caption)
                            .foregroundStyle(SerieColors.gridImportColor())
                        Text("Import")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Text(totalImport.formatWattHoursAsKiloWattsHours(widthUnit: true))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(verbatim: "−\(importCost.formatted(.currency(code: currencyCode)))")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Export
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.caption)
                            .foregroundStyle(SerieColors.gridExportColor())
                        Text("Export")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Text(totalExport.formatWattHoursAsKiloWattsHours(widthUnit: true))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(verbatim: "+\(exportRevenue.formatted(.currency(code: currencyCode)))")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Balance
                VStack(spacing: 4) {
                    Text("Balance")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(netBalance.formatted(.currency(code: currencyCode)))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(netBalance >= 0 ? .green : .red)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill((netBalance >= 0 ? Color.green : Color.red).opacity(0.08))
                )
            }

            // Chart
            if let mainData, !mainData.data.isEmpty {
                let maxKW = mainData.data.map {
                    max(
                        $0.importedOverTimeWhatthours * 12 / 1000,
                        $0.exportedOverTimeWhatthours * 12 / 1000
                    )
                }.max() ?? 1.0

                Chart {
                    GridSeries(
                        data: mainData.data,
                        isAccent: false,
                        gridImportLabel: localizedString("Import"),
                        gridExportLabel: localizedString("Export")
                    )
                }
                .chartYScale(domain: 0...max(maxKW * 1.1, 0.5))
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
                    localizedString("Import"): SerieColors.gridImportColor(),
                    localizedString("Export"): SerieColors.gridExportColor(),
                ])
                .frame(height: 160)
            } else if mainData == nil {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
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
