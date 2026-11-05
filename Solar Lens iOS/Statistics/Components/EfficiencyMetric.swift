import SwiftUI

/// The two efficiency figures a statistics map can tint its tiles by.
enum EfficiencyMetric: String, CaseIterable, Identifiable {
    case autarky
    case selfConsumption

    var id: String { rawValue }

    var label: LocalizedStringKey {
        switch self {
        case .autarky: "Autarky"
        case .selfConsumption: "Self-consumption"
        }
    }

    /// The sentence under a map — what one tile's percentage says.
    var explanation: LocalizedStringKey {
        switch self {
        case .autarky: "Share of consumption covered by your own energy"
        case .selfConsumption: "Share of production you used yourself"
        }
    }

    /// Purple and indigo, as on the home card and the efficiency sheet.
    var color: Color {
        switch self {
        case .autarky: .purple
        case .selfConsumption: .indigo
        }
    }

    /// The figure for one bucket, in percent. `nil` where it is undefined —
    /// no consumption to cover, or no production to keep.
    func value(of statistic: DayStatistic) -> Double? {
        switch self {
        case .autarky: statistic.autarky
        case .selfConsumption: statistic.selfConsumptionRate
        }
    }

    // One hue, stronger for a higher percentage. Kept translucent, like the
    // fills of the intraday chart, so a tile's label can stay in the primary
    // colour in both appearances — and so a weak day is pale rather than red.
    static let minimumTint = 0.06
    static let maximumTint = 0.55

    /// How strongly a tile holding `percent` is tinted.
    func tintStrength(for percent: Double) -> Double {
        Self.minimumTint + (Self.maximumTint - Self.minimumTint) * min(max(percent, 0), 100) / 100
    }
}

/// Chooses the metric a map shows, and reads its tint: left end 0 %, right
/// end 100 %.
struct EfficiencyMetricPicker: View {
    @Binding var metric: EfficiencyMetric

    var body: some View {
        HStack(spacing: 6) {
            ForEach(EfficiencyMetric.allCases) { option in
                SeriesToggle(
                    label: option.label,
                    color: option.color,
                    isOn: Binding(
                        get: { metric == option },
                        set: { _ in metric = option }
                    )
                )
            }

            Spacer(minLength: 0)

            HStack(spacing: 5) {
                Text(verbatim: "0%")
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                metric.color.opacity(EfficiencyMetric.minimumTint),
                                metric.color.opacity(EfficiencyMetric.maximumTint),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 44, height: 6)
                Text(verbatim: "100%")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }
}
