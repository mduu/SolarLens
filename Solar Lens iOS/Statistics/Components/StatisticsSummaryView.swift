import SwiftUI

struct StatisticsSummaryView: View {
    var statistics: Statistics
    var showGridValues: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(
                    title: "Production",
                    value: formatWh(statistics.production),
                    color: .orange
                )
                StatCard(
                    title: "Consumption",
                    value: formatWh(statistics.consumption),
                    color: .blue
                )
            }

            if showGridValues {
                let gridImport = max(0, (statistics.consumption ?? 0) - (statistics.selfConsumption ?? 0))
                let gridExport = max(0, (statistics.production ?? 0) - (statistics.selfConsumption ?? 0))
                HStack(spacing: 12) {
                    StatCard(
                        title: "Grid Import",
                        value: formatWh(gridImport),
                        color: Color(red: 1.0, green: 0.3, blue: 0.15)
                    )
                    StatCard(
                        title: "Grid Export",
                        value: formatWh(gridExport),
                        color: .purple
                    )
                }
            }

            HStack(spacing: 12) {
                StatCard(
                    title: "Self Consumption",
                    value: formatPercent(statistics.selfConsumptionRate),
                    color: .indigo
                )
                StatCard(
                    title: "Autarky",
                    value: formatPercent(statistics.autarchyDegree),
                    color: .purple
                )
            }
        }
    }

    private var useMWh: Bool {
        max(abs(statistics.consumption ?? 0), abs(statistics.production ?? 0)) >= 1_000_000
    }

    private func formatWh(_ value: Double?) -> String {
        guard let value else { return "-" }
        if useMWh {
            return String(format: "%.1f MWh", value / 1_000_000)
        }
        return String(format: "%.1f kWh", value / 1000)
    }

    private func formatPercent(_ value: Double?) -> String {
        guard let value else { return "-" }
        return String(format: "%.0f%%", value)
    }
}

struct StatCard: View {
    var title: LocalizedStringKey
    var value: String
    var color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
