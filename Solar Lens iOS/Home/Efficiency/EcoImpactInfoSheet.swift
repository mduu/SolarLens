import SwiftUI

/// The "i" next to the tree figure, and what it opens.
///
/// The number is an equivalence, not a count of anything that happened — a
/// beta tester read "trees saved" and quite reasonably asked which trees had
/// been in danger. Rather than drop a comparison people like, this explains
/// it: what it means, the reader's own numbers behind it, where the
/// coefficients come from, and which grid they are being compared against.
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
            EcoImpactInfoSheet(totalProductionWh: impact.totalProductionWh)
        }
    }
}

struct EcoImpactInfoSheet: View {
    /// The production rather than a finished `EcoImpact`: the reader can
    /// change the grid region from inside this sheet, and the figures have to
    /// follow them back out of the picker.
    let totalProductionWh: Double

    @AppStorage(GridCarbonRegion.storageKey)
    private var storedRegion = GridCarbonRegion.fallback.rawValue

    @Environment(\.dismiss) private var dismiss

    private var region: GridCarbonRegion {
        GridCarbonRegion(stored: storedRegion)
    }

    private var impact: EcoImpact {
        EcoImpact(totalProductionWh: totalProductionWh, region: region)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        heading("What the number means")
                        explanation(
                            "It is a comparison, not a count — no tree was planted or rescued. Your solar energy replaced electricity that would otherwise have come from the grid, and the CO₂ this avoids is expressed as the number of trees that would bind the same amount over their lifetime."
                        )
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        heading("Your figures")
                        figures
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        heading("Which grid you compare against")
                        regionExplanation
                        regionLink
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        heading("Where the numbers come from")
                        explanation(
                            "The CO₂ per kilowatt-hour is a published average for the grid your system feeds. One tree is taken to bind 18.3 kg of CO₂ a year over a 40-year life."
                        )
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

    private func explanation(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.callout)
            .foregroundStyle(.secondary)
    }

    /// Says plainly whether the figure above flatters the reader. On the
    /// global average it does, in every market this app has users.
    @ViewBuilder
    private var regionExplanation: some View {
        if region == .international {
            explanation(
                "You are comparing against the global average, which is dirtier than any European grid. Where the grid is already clean, solar energy displaces less CO₂ — so the figure above is optimistic. Pick your country to see the saving that actually applies to you."
            )
        } else {
            Text(
                "Your grid region is set to \(region.countryName), at \(region.gramsCo2PerKwh, specifier: "%.0f") g CO₂ per kWh. That is a national average for 2024, so a green tariff or a dirtier hour of the day will differ from it."
            )
            .font(.callout)
            .foregroundStyle(.secondary)
        }
    }

    private var regionLink: some View {
        NavigationLink {
            GridCarbonRegionPicker()
        } label: {
            HStack {
                Text("Grid region")
                Spacer()
                selectedRegionName
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .font(.callout)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.primary.opacity(0.06))
            )
        }
        .buttonStyle(.plain)
        .padding(.top, 2)
    }

    @ViewBuilder
    private var selectedRegionName: some View {
        if region == .international {
            Text("Global average")
        } else {
            Text(verbatim: region.countryName)
        }
    }

    /// The reader's own numbers rather than a formula — labels translate,
    /// values do not.
    private var figures: some View {
        Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 6) {
            row("Produced so far", value(impact.totalProductionWh / 1000, "kWh"))
            row(
                "CO₂ avoided per kWh",
                value(impact.avoidedCo2PerWhInKg * 1_000_000, "g")
            )
            row("CO₂ avoided in total", value(impact.avoidedCo2InKg, "kg"))
            row("CO₂ bound per tree", value(EcoImpact.boundCo2PerTreeInKg, "kg"))
            row("Trees", "\(impact.wholeTrees)")
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
    EcoImpactInfoSheet(totalProductionWh: 40_421_000)
}
