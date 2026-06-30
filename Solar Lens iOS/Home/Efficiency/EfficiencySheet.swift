import SwiftUI

/// Efficiency sheet, opened from the Efficiency card. Available to all users:
/// a period selector showing autarky and self-consumption for the chosen
/// period (consolidating numbers otherwise spread across the Statistics tabs).
/// Non-battery owners (and tester builds) additionally get the battery
/// what-if simulator.
struct EfficiencySheet: View {
    @Environment(\.dismiss) private var dismiss

    let hasAnyBattery: Bool

    @State private var viewModel = EfficiencyViewModel()
    @AppStorage("efficiency.selectedPeriod") private var storedPeriod: String = EfficiencyPeriod.today.rawValue

    // Lifetime "trees saved" figure — shares the cached overall production and
    // formula with the home Efficiency card for consistency.
    @AppStorage("cachedOverallProduction") private var cachedOverallProduction: Double = 0
    private let co2PerWhInKg: Double = 0.00013
    private let boundCo2PerTreePerYearInKg: Double = 20

    private var showWhatIf: Bool { !hasAnyBattery || TesterBuild.isActive }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let isLandscape = geo.size.width > geo.size.height

                if isLandscape && showWhatIf {
                    // Landscape with the simulator: spread the metrics and the
                    // simulator across two independently scrolling columns.
                    HStack(alignment: .top, spacing: 0) {
                        ScrollView {
                            metricsColumn
                                .padding()
                        }
                        .frame(width: geo.size.width / 2)

                        ScrollView {
                            BatteryWhatIfView()
                                .padding()
                        }
                    }
                } else {
                    // Portrait, or no simulator: a single column is enough.
                    ScrollView {
                        VStack(spacing: 16) {
                            metricsColumn

                            if showWhatIf {
                                BatteryWhatIfView()
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Efficiency")
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
        }
        .onAppear {
            if let stored = EfficiencyPeriod(rawValue: storedPeriod) {
                viewModel.selectedPeriod = stored
            }
        }
        .onChange(of: viewModel.selectedPeriod) {
            storedPeriod = viewModel.selectedPeriod.rawValue
            Task { await viewModel.fetch() }
        }
        .task { await viewModel.fetch() }
    }

    // MARK: - Metrics column

    /// Period selector plus the efficiency card. Used as the left column in the
    /// landscape two-column layout and as the top block in the single column.
    private var metricsColumn: some View {
        VStack(spacing: 16) {
            periodPicker
            efficiencyCard
        }
    }

    // MARK: - Period selector

    private var periodPicker: some View {
        Picker("Period", selection: $viewModel.selectedPeriod) {
            ForEach(EfficiencyPeriod.allCases) { period in
                Text(period.localizedName).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Efficiency card

    private var efficiencyCard: some View {
        VStack(spacing: 16) {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
            } else {
                HStack(spacing: 12) {
                    EfficiencyMetricTile(
                        title: "Self-consumption",
                        value: viewModel.selfConsumptionPercent,
                        color: .indigo,
                        systemImage: "bolt.fill"
                    )
                    EfficiencyMetricTile(
                        title: "Autarky",
                        value: viewModel.autarkyPercent,
                        color: .purple,
                        systemImage: "house.fill"
                    )
                }

                supportingFigures
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    private var supportingFigures: some View {
        VStack(spacing: 8) {
            Divider()
            HStack {
                figure("Consumption", viewModel.consumptionWh, color: .teal)
                Spacer()
                figure("Production", viewModel.productionWh, color: .yellow)
            }

            HStack {
                figure("Grid export", viewModel.gridExportWh, color: .green)
                Spacer()
                figure("Grid import", viewModel.gridImportWh, color: .red)
            }

            treesEquivalentView
        }
    }

    @ViewBuilder
    private var treesEquivalentView: some View {
        if cachedOverallProduction > 0 {
            let co2Avoided = cachedOverallProduction / 10 * co2PerWhInKg
            let treesEquivalent = max(1, co2Avoided / boundCo2PerTreePerYearInKg)
            HStack(spacing: 5) {
                Image(systemName: "leaf.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
                Text("\(treesEquivalent, specifier: "%.0f") trees saved")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                Text("(\(co2Avoided, specifier: "%.1f") kg CO₂)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 2)
        }
    }

    private func figure(_ title: LocalizedStringKey, _ valueWh: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(valueWh.formatWattHoursAsKiloWattsHours(widthUnit: true))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
    }
}

/// A single efficiency metric shown with the same 180° gauge arc as the home
/// Efficiency card, for visual consistency and recognition.
private struct EfficiencyMetricTile: View {
    let title: LocalizedStringKey
    let value: Double?
    let color: Color
    let systemImage: String

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.caption2)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.8))
            }

            GaugeArc(percentage: value ?? 0, color: color)
                .frame(width: 84, height: 48)

            Text((value ?? 0).formatIntoPercentage())
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("No battery") {
    EfficiencySheet(hasAnyBattery: false)
}

#Preview("Has battery") {
    EfficiencySheet(hasAnyBattery: true)
}
