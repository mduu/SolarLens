import Charts
import SwiftUI

/// When and how much the car was charged: today's charging power as a curve,
/// and the energy of the last seven days as one bar per day.
struct ChargingHistoryCard: View {
    @Environment(CurrentBuildingState.self) var buildingState: CurrentBuildingState
    @Environment(\.energyManager) private var energyManager

    /// Side by side where there is room, stacked in a sheet or pane.
    var sideBySide = false

    @State private var history: [ChargingHistory] = []
    @State private var isLoading = false
    @State private var loadFailed = false

    private var calendar: Calendar { Calendar.current }
    private var startOfToday: Date { calendar.startOfDay(for: Date()) }
    private var rangeStart: Date {
        calendar.date(byAdding: .day, value: -6, to: startOfToday) ?? startOfToday
    }

    var body: some View {
        let stack = sideBySide
            ? AnyLayout(HStackLayout(alignment: .top, spacing: 16))
            : AnyLayout(VStackLayout(spacing: 16))

        stack {
            todayCard
            weekCard
        }
        .task {
            await load()
        }
    }

    // MARK: - Today

    private var todayCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            header(
                "Charging today", systemImage: "bolt.car",
                value: energyText(todayPoints.reduce(0) { $0 + $1.point.energyWh })
            )

            if todayPoints.contains(where: { $0.point.powerW > 0 }) {
                Chart(todayPoints) { sample in
                    AreaMark(
                        x: .value("Time", sample.point.date),
                        y: .value("Power", sample.point.powerW / 1000),
                        stacking: .standard
                    )
                    .foregroundStyle(by: .value("Station", sample.station))
                    .interpolationMethod(.stepEnd)
                }
                .chartXScale(domain: startOfToday...endOfToday)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .hour, count: 6)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.hour())
                    }
                }
                .chartYAxisLabel("kW")
                .chartLegend(stationNames.count > 1 ? .visible : .hidden)
                .frame(height: 180)
            } else {
                placeholder("No charging today")
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .frame(maxWidth: .infinity)
    }

    // MARK: - Last 7 days

    private var weekCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            header(
                "Last 7 days", systemImage: "calendar",
                value: energyText(dayTotals.reduce(0) { $0 + $1.energyWh })
            )

            if dayTotals.contains(where: { $0.energyWh > 0 }) {
                Chart(dayTotals) { total in
                    BarMark(
                        x: .value("Day", total.day, unit: .day),
                        y: .value("Energy", total.energyWh / 1000)
                    )
                    .foregroundStyle(by: .value("Station", total.station))
                    .cornerRadius(3)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated), centered: true)
                    }
                }
                .chartYAxisLabel("kWh")
                .chartLegend(stationNames.count > 1 ? .visible : .hidden)
                .frame(height: 180)
            } else {
                placeholder("No charging in the last 7 days")
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .frame(maxWidth: .infinity)
    }

    // MARK: - Pieces

    private func header(
        _ title: LocalizedStringKey, systemImage: String, value: String
    ) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            if isLoading && history.isEmpty {
                ProgressView()
                    .controlSize(.small)
            } else {
                Text(value)
                    .font(.headline)
                    .monospacedDigit()
            }
        }
    }

    private func placeholder(_ text: LocalizedStringKey) -> some View {
        Text(loadFailed ? "Could not load the charging history." : text)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .frame(height: 180)
    }

    private func energyText(_ wattHours: Double) -> String {
        wattHours.formatWattHoursAsKiloWattsHours(widthUnit: true)
    }

    // MARK: - Data

    private struct Sample: Identifiable {
        let id: UUID
        let station: String
        let point: ChargingHistoryPoint
    }

    private struct DayTotal: Identifiable {
        var id: String { "\(station)-\(day.timeIntervalSince1970)" }
        let station: String
        let day: Date
        let energyWh: Double
    }

    private var endOfToday: Date {
        calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? Date()
    }

    private var stationNames: [String: String] {
        Dictionary(
            buildingState.overviewData.chargingStations.map { ($0.id, $0.name) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    private func name(of stationId: String) -> String {
        stationNames[stationId] ?? String(localized: "Charging station")
    }

    private var todayPoints: [Sample] {
        history.flatMap { station in
            station.points
                .filter { $0.date >= startOfToday }
                .map { Sample(id: $0.id, station: name(of: station.stationId), point: $0) }
        }
    }

    /// One total per station and day, including the days nothing was
    /// charged, so the week always shows seven slots.
    private var dayTotals: [DayTotal] {
        let days = (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: rangeStart)
        }
        return history.flatMap { station in
            let byDay = Dictionary(grouping: station.points) {
                calendar.startOfDay(for: $0.date)
            }
            return days.map { day in
                DayTotal(
                    station: name(of: station.stationId),
                    day: day,
                    energyWh: byDay[day]?.reduce(0) { $0 + $1.energyWh } ?? 0
                )
            }
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            history = try await energyManager.fetchChargingHistory(
                from: rangeStart, to: Date()
            )
            loadFailed = false
        } catch {
            loadFailed = true
        }
    }
}

#Preview {
    ScrollView {
        ChargingHistoryCard()
            .padding()
    }
    .environment(
        CurrentBuildingState.fake(
            overviewData: OverviewData.fake()
        )
    )
}
