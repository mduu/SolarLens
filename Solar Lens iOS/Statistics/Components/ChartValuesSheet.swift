import SwiftUI

/// The numbers behind the bars, as a table.
///
/// A bar chart on a touch device has nowhere to hang a tooltip, and a table
/// pinned under the chart would cost it most of its height for something the
/// reader wants only now and then. So the values sit one tap away: a popover
/// where there is room for one, a sheet on a phone.
///
/// Exporting lives here too rather than in the chart's own header. The two
/// were offering the same figures from two different buttons, and this way
/// the file is described by what is on screen when it is sent.
struct ChartValuesSheet: View {
    /// The window the figures describe — the same label the ‹ › header shows.
    let title: String

    /// The buckets currently on screen, in the order the chart draws them, so
    /// the first row is the leftmost bar.
    let rows: [DayStatistic]

    /// How wide one bucket is, which is what its row is labelled by.
    let bucket: Calendar.Component

    /// Only the series the chart is currently drawing — a column for a bar
    /// that is switched off would describe nothing on screen.
    let series: [StatisticsSeries]

    /// Writes the rows to a file and hands back its URL, or `nil` when there
    /// is nothing to write. The screen owns the exporter; the sheet only says
    /// when and in which format.
    let exportFile: (ExportFormat) async -> URL?

    @Environment(\.dismiss) private var dismiss

    @State private var shareURLs: [URL] = []
    @State private var showShare = false
    @State private var isExporting = false

    /// One unit for the whole table. A column mixing kWh and MWh cannot be
    /// compared by eye, which is the entire point of showing it.
    private var useMWh: Bool {
        let peak = rows.flatMap { row in series.map { $0.value(in: row) } }.max() ?? 0
        return peak / 1000 >= 1000
    }

    private var unitLabel: String { useMWh ? "MWh" : "kWh" }

    var body: some View {
        NavigationStack {
            Group {
                if rows.isEmpty || series.isEmpty {
                    ContentUnavailableView(
                        "No Data Available",
                        systemImage: "tablecells",
                        description: Text(
                            "Statistics will appear here when data is available."
                        )
                    )
                } else {
                    ScrollView {
                        table
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    exportMenu
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showShare) {
                ShareSheet(activityItems: shareURLs)
            }
        }
    }

    @ViewBuilder
    private var exportMenu: some View {
        if !rows.isEmpty {
            Menu {
                Button("CSV") { export(.csv) }
                Button("Excel (.xlsx)") { export(.xlsx) }
            } label: {
                if isExporting {
                    ProgressView().controlSize(.mini)
                } else {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            .disabled(isExporting)
            .accessibilityLabel("Export")
        }
    }

    private func export(_ format: ExportFormat) {
        isExporting = true
        Task {
            defer { isExporting = false }
            guard let url = await exportFile(format) else { return }
            shareURLs = [url]
            showShare = true
        }
    }

    private var table: some View {
        Grid(alignment: .trailing, horizontalSpacing: 10, verticalSpacing: 7) {
            // Name and unit are separate rows so a label that wraps — the
            // German for "consumption" is long — pushes only itself down and
            // leaves every unit sitting on one line.
            GridRow(alignment: .bottom) {
                Text("Period")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .gridColumnAlignment(.leading)

                ForEach(series) { header(for: $0) }
            }

            GridRow {
                Text(verbatim: "")
                    .gridColumnAlignment(.leading)

                ForEach(series) { _ in
                    Text(unitLabel)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }

            Divider().gridCellUnsizedAxes(.horizontal).gridCellColumns(series.count + 1)

            ForEach(rows, id: \.day) { row in
                GridRow {
                    Text(rowLabel(row.day))
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .gridColumnAlignment(.leading)

                    ForEach(series) { serie in
                        Text(serie.value(in: row).formatWattHours(asMWh: useMWh))
                            .font(.caption)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                }
            }

            Divider().gridCellUnsizedAxes(.horizontal).gridCellColumns(series.count + 1)

            GridRow {
                Text("Total")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .gridColumnAlignment(.leading)

                ForEach(series) { serie in
                    Text(total(of: serie).formatWattHours(asMWh: useMWh))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
        }
    }

    private func header(for serie: StatisticsSeries) -> some View {
        VStack(spacing: 3) {
            Circle()
                .fill(serie.color)
                .frame(width: 8, height: 8)

            Text(serie.label)
                .font(.caption2)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.trailing)
        }
    }

    private func total(of serie: StatisticsSeries) -> Double {
        rows.reduce(0) { $0 + serie.value(in: $1) }
    }

    /// Labels a row the way the chart labels that bar's slot on the x axis.
    private func rowLabel(_ date: Date) -> String {
        switch bucket {
        case .weekOfYear:
            let week = Calendar(identifier: .iso8601).component(.weekOfYear, from: date)
            return "W\(week)"
        case .month:
            return date.formatted(.dateTime.month(.abbreviated).year())
        case .year:
            return date.formatted(.dateTime.year())
        default:
            return date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        }
    }
}

private func previewRows() -> [DayStatistic] {
    var rows: [DayStatistic] = []
    let calendar = Calendar.current
    for offset in 0..<6 {
        guard let day = calendar.date(byAdding: .day, value: offset, to: Date()) else { continue }
        let step = Double(offset)
        rows.append(
            DayStatistic(
                day: day,
                consumption: 28_000 + step * 1_500,
                production: 41_000 - step * 900,
                imported: 4_000 + step * 200,
                exported: 9_000 - step * 300
            )
        )
    }
    return rows
}

#Preview {
    ChartValuesSheet(
        title: "September 2026",
        rows: previewRows(),
        bucket: .day,
        series: StatisticsSeries.allCases,
        exportFile: { _ in nil }
    )
}
