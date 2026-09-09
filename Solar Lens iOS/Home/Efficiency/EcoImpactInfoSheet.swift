import SwiftUI

/// The "i" next to the tree figure, and what it opens.
///
/// The number is an equivalence, not a count of anything that happened — a
/// beta tester read "trees saved" and quite reasonably asked which trees had
/// been in danger. Rather than drop a comparison people like, this explains
/// it: what it means, the reader's own numbers behind it, where the
/// coefficients come from, and why the figure flatters a European grid.
struct EcoImpactInfoButton: View {
    let impact: EcoImpact

    @State private var isShown = false

    var body: some View {
        Button {
            isShown = true
        } label: {
            // Same blue ⓘ as the battery simulator's parameter hints one
            // section below, so the two read as the same affordance.
            Label("About the tree comparison", systemImage: "info.circle")
                .labelStyle(.iconOnly)
                .font(.footnote)
                .foregroundStyle(.blue)
                // Inside the label, not around the Button: a bare glyph
                // otherwise hit-tests only its own drawn pixels, which is the
                // trap the sheets' close buttons fell into.
                .frame(minWidth: 28, minHeight: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isShown) {
            EcoImpactInfoSheet(impact: impact)
        }
    }
}

struct EcoImpactInfoSheet: View {
    let impact: EcoImpact

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        heading("What the number means")
                        Text(
                            "It is a comparison, not a count — no tree was planted or rescued. Your solar energy replaced electricity that would otherwise have come from the grid, and the CO₂ this avoids is expressed as the number of trees that would bind the same amount over their lifetime."
                        )
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        heading("Your figures")
                        figures
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        heading("Where the numbers come from")
                        Text(
                            "The CO₂ per kilowatt-hour is the global average published by the International Energy Agency. One tree is taken to bind 18.3 kg of CO₂ a year over a 40-year life. Solar Lens uses the same coefficients as the Huawei FusionSolar app, so both show the same result for the same system."
                        )
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        heading("In Europe it looks different")
                        Text(
                            "The global average lies far above most European grids — Swiss electricity is around 55 g CO₂ per kWh, German around 363 g. Where the grid is already clean, solar energy displaces less CO₂, so the real saving is smaller than the figure shown; in Switzerland considerably so."
                        )
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("About the tree comparison")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func heading(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.subheadline)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The reader's own numbers rather than a formula — labels translate,
    /// values do not.
    private var figures: some View {
        Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 6) {
            row("Produced so far", value(impact.totalProductionWh / 1000, "kWh"))
            row(
                "CO₂ avoided per kWh",
                value(EcoImpact.avoidedCo2PerWhInKg * 1_000_000, "g")
            )
            row("CO₂ avoided in total", value(impact.avoidedCo2InKg, "kg"))
            row("CO₂ bound per tree", value(EcoImpact.boundCo2PerTreeInKg, "kg"))
            row("Trees", value(impact.equivalentTrees, ""))
        }
        .font(.callout)
    }

    private func row(_ label: LocalizedStringKey, _ text: String) -> some View {
        GridRow {
            Text(label)
                .foregroundStyle(.secondary)
            Text(verbatim: text)
                .fontWeight(.medium)
                .monospacedDigit()
                .gridColumnAlignment(.trailing)
        }
    }

    private func value(_ number: Double, _ unit: String) -> String {
        let formatted = number.formatted(.number.precision(.fractionLength(0)))
        return unit.isEmpty ? formatted : "\(formatted) \(unit)"
    }
}

#Preview {
    EcoImpactInfoSheet(impact: EcoImpact(totalProductionWh: 40_421_000))
}
