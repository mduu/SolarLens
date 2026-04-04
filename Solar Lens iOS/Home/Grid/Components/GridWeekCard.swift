import Charts
import SwiftUI

struct GridWeekCard: View {
    let weekData: [DayGridSummary]
    let tariffSettings: TariffSettingsV3Response?
    let fallbackTariff: TariffV1Response?

    var body: some View {
        let currencyCode = CurrencyHelper.currencyCode

        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.7))
                Text("Electricity costs last 7 days")
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.7))
            }

            VStack(spacing: 0) {
                ForEach(Array(weekData.enumerated()), id: \.element.id) { index, day in
                    let importCost = TariffCalculator.gridImportCost(
                        data: day.data, tariffSettings: tariffSettings, fallbackTariff: fallbackTariff)
                    let exportRevenue = TariffCalculator.gridExportRevenue(
                        data: day.data, tariffSettings: tariffSettings, fallbackTariff: fallbackTariff)
                    let netBalance = exportRevenue - importCost

                    HStack(alignment: .top, spacing: 4) {
                        // Column 1: Day
                        Text(day.date, format: .dateTime.weekday(.short))
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(width: 22, alignment: .leading)
                            .padding(.top, 2)

                        // Column 2: kWh values
                        VStack(alignment: .trailing, spacing: 2) {
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.down")
                                    .font(.system(size: 7))
                                    .foregroundStyle(SerieColors.gridImportColor())
                                Text(day.totalImportWh.formatWattHoursAsKiloWattsHours(widthUnit: true))
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 7))
                                    .foregroundStyle(SerieColors.gridExportColor())
                                Text(day.totalExportWh.formatWattHoursAsKiloWattsHours(widthUnit: true))
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                        }
                        .frame(width: 72, alignment: .trailing)

                        // Column 3: Prices
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(verbatim: "−\(importCost.formatted(.currency(code: currencyCode)))")
                                .font(.caption2)
                                .foregroundStyle(.red)
                            Text(verbatim: "+\(exportRevenue.formatted(.currency(code: currencyCode)))")
                                .font(.caption2)
                                .foregroundStyle(.green)
                        }
                        .frame(width: 72, alignment: .trailing)

                        Spacer(minLength: 0)

                        // Column 4: Balance
                        Text(netBalance.formatted(.currency(code: currencyCode)))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(netBalance >= 0 ? .green : .red)
                            .frame(width: 72, alignment: .trailing)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.top, 2)

                        // Column 4: Mini chart
                        DayMiniChart(data: day.data)
                            .frame(width: 90, height: 36)
                    }
                    .padding(.vertical, 5)

                    if index < weekData.count - 1 {
                        Divider().opacity(0.2)
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

// MARK: - Mini chart for a single day

private struct DayMiniChart: View {
    let data: [MainDataItem]

    var body: some View {
        let hasExport = data.contains { $0.exportedOverTimeWhatthours > 0 }

        Canvas { context, size in
            guard data.count > 1 else { return }

            let maxImport = data.map { $0.importedOverTimeWhatthours }.max() ?? 1
            let maxExport = data.map { $0.exportedOverTimeWhatthours }.max() ?? 1
            let stepX = size.width / CGFloat(data.count - 1)

            // Draw import area + line
            if maxImport > 0 {
                var areaPath = Path()
                var linePath = Path()
                for (i, point) in data.enumerated() {
                    let x = CGFloat(i) * stepX
                    let y = size.height * (1 - CGFloat(point.importedOverTimeWhatthours / maxImport))
                    if i == 0 {
                        areaPath.move(to: CGPoint(x: x, y: y))
                        linePath.move(to: CGPoint(x: x, y: y))
                    } else {
                        areaPath.addLine(to: CGPoint(x: x, y: y))
                        linePath.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                areaPath.addLine(to: CGPoint(x: size.width, y: size.height))
                areaPath.addLine(to: CGPoint(x: 0, y: size.height))
                areaPath.closeSubpath()

                context.fill(
                    areaPath,
                    with: .linearGradient(
                        Gradient(colors: [
                            Color.red.opacity(0.3),
                            Color.red.opacity(0.03),
                        ]),
                        startPoint: .zero,
                        endPoint: CGPoint(x: 0, y: size.height)
                    )
                )
                context.stroke(linePath, with: .color(.red.opacity(0.8)), lineWidth: 1)
            }

            // Draw export area + line
            if hasExport && maxExport > 0 {
                var areaPath = Path()
                var linePath = Path()
                for (i, point) in data.enumerated() {
                    let x = CGFloat(i) * stepX
                    let y = size.height * (1 - CGFloat(point.exportedOverTimeWhatthours / maxExport))
                    if i == 0 {
                        areaPath.move(to: CGPoint(x: x, y: y))
                        linePath.move(to: CGPoint(x: x, y: y))
                    } else {
                        areaPath.addLine(to: CGPoint(x: x, y: y))
                        linePath.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                areaPath.addLine(to: CGPoint(x: size.width, y: size.height))
                areaPath.addLine(to: CGPoint(x: 0, y: size.height))
                areaPath.closeSubpath()

                context.fill(
                    areaPath,
                    with: .linearGradient(
                        Gradient(colors: [
                            Color.green.opacity(0.4),
                            Color.green.opacity(0.03),
                        ]),
                        startPoint: .zero,
                        endPoint: CGPoint(x: 0, y: size.height)
                    )
                )
                context.stroke(linePath, with: .color(.green.opacity(0.9)), lineWidth: 1)
            }
        }
    }
}

struct DayGridSummary: Identifiable {
    let id: Date
    let date: Date
    let data: [MainDataItem]

    var totalImportWh: Double {
        data.reduce(0.0) { $0 + $1.importedOverTimeWhatthours }
    }

    var totalExportWh: Double {
        data.reduce(0.0) { $0 + $1.exportedOverTimeWhatthours }
    }
}
