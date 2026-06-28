import SwiftUI

/// "What if I had a battery?" — lets a non-owner pick a year and battery size,
/// replays their real data through a virtual battery using their real tariffs,
/// and reports the money they could have saved plus the autarky and
/// self-consumption they would have gained.
struct BatteryWhatIfView: View {
    @State private var viewModel = BatteryWhatIfViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            inputs

            Button(action: { Task { await viewModel.run() } }) {
                HStack {
                    Spacer()
                    if viewModel.isRunning {
                        Text("Simulating…")
                    } else {
                        Image(systemName: "play.fill")
                        Text("Run simulation")
                    }
                    Spacer()
                }
                .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(viewModel.isRunning)

            if viewModel.isRunning {
                progressView
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            if viewModel.hasRun, let result = viewModel.customResult {
                resultsView(custom: result)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.green)
                Text("What if I had a battery?")
                    .font(.headline)
            }
            Text("Replays a past year of your own data through a virtual battery, using your real tariffs.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Inputs

    private var inputs: some View {
        VStack(spacing: 12) {
            HStack {
                parameterLabel(
                    "Year",
                    infoTitle: "Simulation year",
                    infoMessage: "The past year whose real production and consumption we replay through a virtual battery. Pick a full year for the most representative result.",
                    topic: .year
                )
                Spacer()
                Picker("Year", selection: $viewModel.selectedYear) {
                    ForEach(viewModel.availableYears, id: \.self) { year in
                        Text(verbatim: "\(year)").tag(year)
                    }
                }
                .pickerStyle(.menu)
            }

            Stepper(
                value: $viewModel.customCapacityKwh, in: 1...50, step: 1
            ) {
                HStack {
                    parameterLabel(
                        "Battery size",
                        infoTitle: "Battery size (kWh)",
                        infoMessage: "How much energy the battery can store, in kilowatt-hours (kWh). A bigger battery keeps more of your daytime solar surplus for the evening and night — but costs more. Typical home batteries are 5–15 kWh.",
                        topic: .capacity
                    )
                    Spacer()
                    Text(verbatim: String(format: "%.0f kWh", viewModel.customCapacityKwh))
                        .foregroundStyle(.secondary)
                }
            }

            Stepper(
                value: $viewModel.maxPowerKw, in: 1...20, step: 0.5
            ) {
                HStack {
                    parameterLabel(
                        "Max charge / discharge power",
                        infoTitle: "Charge & discharge power (kW)",
                        infoMessage: "How fast the battery can fill up or empty, in kilowatts (kW). More power lets it soak up a strong midday solar peak or instantly cover a big load like an oven or EV charger. Many home batteries handle about 5–10 kW.",
                        topic: .power
                    )
                    Spacer()
                    Text(verbatim: String(format: "%.1f kW", viewModel.maxPowerKw))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    parameterLabel(
                        "Round-trip efficiency",
                        infoTitle: "Round-trip efficiency",
                        infoMessage: "Storing and retrieving energy isn't free — a little is lost as heat. Round-trip efficiency is how much you get back out compared with what you put in. About 90% is typical: store 10 kWh, get roughly 9 kWh back.",
                        topic: .efficiency
                    )
                    Spacer()
                    Text(verbatim: String(format: "%.0f%%", viewModel.roundTripEfficiencyPercent))
                        .foregroundStyle(.secondary)
                }
                Slider(value: $viewModel.roundTripEfficiencyPercent, in: 70...100, step: 1)
            }
        }
        .font(.subheadline)
    }

    private func parameterLabel(
        _ title: LocalizedStringKey,
        infoTitle: LocalizedStringKey,
        infoMessage: LocalizedStringKey,
        topic: SimulatorInfoTopic
    ) -> some View {
        HStack(spacing: 4) {
            Text(title)
            ParameterInfoButton(title: infoTitle, message: infoMessage, topic: topic)
        }
    }

    // MARK: - Progress

    private var progressView: some View {
        VStack(alignment: .leading, spacing: 4) {
            ProgressView(value: viewModel.progress)
                .tint(.green)
            Text(verbatim: "\(Int(viewModel.progress * 100))%")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Results

    @ViewBuilder
    private func resultsView(custom: BatterySimulationResult) -> some View {
        Divider()

        VStack(alignment: .leading, spacing: 12) {
            // Headline verdict for the chosen custom size.
            VStack(alignment: .leading, spacing: 6) {
                Text("With a \(String(format: "%.0f", custom.capacityKwh)) kWh battery in \(String(viewModel.selectedYear))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(verbatim: formatSavings(custom.netSavings))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.green)

                Text("estimated savings (rounded)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 0) {
                improvement("Autarky", custom.autarkyWithout, custom.autarkyWith, color: .purple)
                Spacer()
                improvement("Self-consumption", custom.selfConsumptionWithout, custom.selfConsumptionWith, color: .indigo)
            }

            // Reduced grid interaction thanks to the battery.
            HStack(spacing: 0) {
                gridFigure("Grid import avoided", custom.avoidedImportWh, color: .red)
                Spacer()
                gridFigure("Grid export kept", custom.reducedExportWh, color: .green)
            }

            // Size comparison sweep.
            if !viewModel.sweepResults.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Compare sizes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(viewModel.sweepResults) { sweep in
                        HStack {
                            Text(verbatim: String(format: "%.0f kWh", sweep.capacityKwh))
                                .font(.subheadline)
                            Spacer()
                            Text("+\(sweep.autarkyImprovement, specifier: "%.0f")% autarky")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(verbatim: formatSavings(sweep.netSavings))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.green)
                        }
                    }
                }
            }

            TariffRatesFootnote(
                importRate: custom.effectiveImportRate,
                feedInRate: custom.effectiveFeedInRate
            )

            footnotes
        }
    }

    /// Savings rounded to the nearest 100 currency units (it is an estimate),
    /// formatted with no fraction digits.
    private func formatSavings(_ value: Double) -> String {
        let rounded = (value / 100).rounded() * 100
        return rounded.formatted(
            .currency(code: CurrencyHelper.currencyCode).precision(.fractionLength(0))
        )
    }

    private func gridFigure(_ title: LocalizedStringKey, _ valueWh: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(valueWh.formatWattHoursAsKiloWattsHours(widthUnit: true))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
    }

    private func improvement(_ title: LocalizedStringKey, _ without: Double, _ with: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("+\(with - without, specifier: "%.1f")%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
                Text("\(with, specifier: "%.0f")%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("Today: \(without, specifier: "%.0f")%")
                .font(.caption2)
                .foregroundStyle(.primary.opacity(0.5))
        }
    }

    private var footnotes: some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider()
            Label(
                "Estimate only — not a guarantee. Actual results depend on the device, degradation, and future consumption.",
                systemImage: "info.circle"
            )
            Label(
                "Conservative lower bound. Actively managing the battery (e.g. charging the EV from the battery before leaving so it can buffer more solar, or tariff arbitrage) can save even more.",
                systemImage: "arrow.up.forward"
            )
            Text("Assumes \(viewModel.minStateOfChargePercent)% minimum charge reserve, \(viewModel.maxPowerKw, specifier: "%.1f") kW max power, \(viewModel.roundTripEfficiencyPercent, specifier: "%.0f")% round-trip efficiency.")
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
}

// MARK: - Parameter info popovers

private enum SimulatorInfoTopic {
    case year, capacity, power, efficiency
}

/// A small ⓘ button that opens a popover explaining a simulator parameter in
/// plain language, with a custom-drawn illustration — for users unfamiliar
/// with battery terms.
private struct ParameterInfoButton: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let topic: SimulatorInfoTopic

    @State private var show = false

    var body: some View {
        Button { show = true } label: {
            Image(systemName: "info.circle")
                .font(.footnote)
                .foregroundStyle(.blue)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $show) {
            VStack(spacing: 14) {
                SimulatorIllustration(topic: topic)
                    .frame(height: 92)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.08))
                    )

                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .frame(width: 300)
            .presentationCompactAdaptation(.popover)
        }
    }
}

private struct SimulatorIllustration: View {
    let topic: SimulatorInfoTopic

    var body: some View {
        switch topic {
        case .year: YearIllustration()
        case .capacity: CapacityIllustration()
        case .power: PowerIllustration()
        case .efficiency: EfficiencyIllustration()
        }
    }
}

/// A battery body whose green fill reflects `fillFraction` (0–1).
private struct BatteryGlyph: View {
    var fillFraction: Double
    var fillColor: Color = .green

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.primary.opacity(0.5), lineWidth: 2)
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 3)
                    .fill(fillColor.gradient)
                    .frame(
                        width: max((geo.size.width - 6) * fillFraction, 4),
                        height: geo.size.height - 6
                    )
                    .offset(x: 3, y: 3)
            }
        }
    }
}

private struct BatteryWithTerminal: View {
    var fillFraction: Double
    var width: CGFloat = 58
    var height: CGFloat = 32

    var body: some View {
        HStack(spacing: 2) {
            BatteryGlyph(fillFraction: fillFraction)
                .frame(width: width, height: height)
            Capsule()
                .fill(Color.primary.opacity(0.5))
                .frame(width: 4, height: height * 0.4)
        }
    }
}

/// Sun feeding a partly-filled battery — "how much it can store".
private struct CapacityIllustration: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sun.max.fill")
                .font(.title2)
                .foregroundStyle(.yellow)
            Image(systemName: "arrow.right")
                .font(.caption)
                .foregroundStyle(.secondary)
            BatteryWithTerminal(fillFraction: 0.7, width: 64, height: 36)
        }
    }
}

/// Energy flowing into and out of the battery — "how fast it charges/discharges".
private struct PowerIllustration: View {
    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                Image(systemName: "arrow.down")
                    .foregroundStyle(.green)
                Text("charge")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
            }
            ZStack {
                BatteryWithTerminal(fillFraction: 0.5, width: 58, height: 34)
                Image(systemName: "bolt.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
                    .offset(x: -2)
            }
            VStack(spacing: 2) {
                Image(systemName: "arrow.up")
                    .foregroundStyle(.orange)
                Text("discharge")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// In vs. out with a little lost as heat — "round-trip efficiency".
private struct EfficiencyIllustration: View {
    var body: some View {
        HStack(spacing: 10) {
            VStack(spacing: 2) {
                Text("In").font(.system(size: 9)).foregroundStyle(.secondary)
                Text(verbatim: "10 kWh").font(.caption).fontWeight(.semibold)
            }
            VStack(spacing: 1) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.title3)
                    .foregroundStyle(.green)
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill").font(.system(size: 8)).foregroundStyle(.orange)
                    Text("−10%").font(.system(size: 8)).foregroundStyle(.secondary)
                }
            }
            VStack(spacing: 2) {
                Text("Out").font(.system(size: 9)).foregroundStyle(.secondary)
                Text(verbatim: "9 kWh").font(.caption).fontWeight(.semibold).foregroundStyle(.green)
            }
        }
    }
}

/// A year of solar production — taller bars in summer — under a sun.
private struct YearIllustration: View {
    private let monthly: [CGFloat] = [0.30, 0.42, 0.58, 0.74, 0.88, 0.98, 1.0, 0.92, 0.72, 0.52, 0.36, 0.28]

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "sun.max.fill")
                .font(.caption)
                .foregroundStyle(.yellow)
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(monthly.indices, id: \.self) { i in
                    Capsule()
                        .fill(Color.yellow.gradient)
                        .frame(width: 6, height: 44 * monthly[i])
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        BatteryWhatIfView()
            .padding()
    }
}

#Preview("Illustrations") {
    VStack(spacing: 12) {
        ForEach([SimulatorInfoTopic.capacity, .power, .efficiency, .year], id: \.self) { topic in
            SimulatorIllustration(topic: topic)
                .frame(height: 92)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.green.opacity(0.08)))
        }
    }
    .padding()
}
