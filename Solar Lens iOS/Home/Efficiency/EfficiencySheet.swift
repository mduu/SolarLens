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

    private var showWhatIf: Bool { !hasAnyBattery || TesterBuild.isActive }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    periodPicker

                    efficiencyCard

                    if showWhatIf {
                        BatteryWhatIfView()
                    }
                }
                .padding()
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
                        title: "Autarky",
                        value: viewModel.autarkyPercent,
                        color: .purple,
                        systemImage: "house.fill"
                    )
                    EfficiencyMetricTile(
                        title: "Self-consumption",
                        value: viewModel.selfConsumptionPercent,
                        color: .indigo,
                        systemImage: "bolt.fill"
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
                figure("Production", viewModel.productionWh, color: .yellow)
                Spacer()
                figure("Consumption", viewModel.consumptionWh, color: .teal)
            }
            HStack {
                figure("Grid import", viewModel.gridImportWh, color: .red)
                Spacer()
                figure("Grid export", viewModel.gridExportWh, color: .green)
            }
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

/// A single big efficiency percentage with a capsule progress bar.
private struct EfficiencyMetricTile: View {
    let title: LocalizedStringKey
    let value: Double?
    let color: Color
    let systemImage: String

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.caption2)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.8))
            }

            Text((value ?? 0).formatIntoPercentage())
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(color)
                .contentTransition(.numericText())

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(color.opacity(0.15))
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(min((value ?? 0) / 100, 1)))
                }
            }
            .frame(height: 6)
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
