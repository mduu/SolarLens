import SwiftUI

/// Where the system stands, so the CO₂ figure can mean something.
///
/// Reached from two places — Settings, and the tree explanation itself, which
/// is where a reader is most likely to notice the number is wrong for them.
struct GridCarbonRegionPicker: View {
    @AppStorage(GridCarbonRegion.storageKey)
    private var stored = GridCarbonRegion.fallback.rawValue

    private var selection: GridCarbonRegion { GridCarbonRegion(stored: stored) }

    var body: some View {
        List {
            Section {
                ForEach(GridCarbonRegion.allCases) { region in
                    Button {
                        stored = region.rawValue
                    } label: {
                        row(for: region)
                    }
                    .buttonStyle(.plain)
                }
            } footer: {
                Text(
                    "Solar energy replaces electricity that would otherwise come from the grid. How much CO₂ that avoids depends on how clean the grid already is, so pick where your system stands. National figures are averages for 2024; the global average is the one published by the International Energy Agency."
                )
            }
        }
        .navigationTitle("Grid region")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(for region: GridCarbonRegion) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                label(for: region)
                Text("\(region.gramsCo2PerKwh, specifier: "%.0f") g CO₂ per kWh")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark")
                .font(.body.weight(.semibold))
                .foregroundStyle(.blue)
                .opacity(region == selection ? 1 : 0)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(region == selection ? [.isButton, .isSelected] : .isButton)
    }

    /// Country names come from the system in the reader's language; only the
    /// global average is a string of ours.
    @ViewBuilder
    private func label(for region: GridCarbonRegion) -> some View {
        if region == .international {
            Text("Global average")
        } else {
            Text(verbatim: region.countryName)
        }
    }
}

#Preview {
    NavigationStack {
        GridCarbonRegionPicker()
    }
}
