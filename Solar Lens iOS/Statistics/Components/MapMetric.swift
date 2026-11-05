import SwiftUI

/// What a statistics map tints its tiles by.
enum MapMetric: String, CaseIterable, Identifiable {
    /// Share of consumption the house covered itself.
    case autarky
    /// Share of production that stayed in the house.
    case selfConsumption
    /// Production minus consumption: surplus one way, deficit the other.
    case balance

    var id: String { rawValue }

    var label: LocalizedStringKey {
        switch self {
        case .autarky: "Autarky"
        case .selfConsumption: "Self-consumption"
        case .balance: "Balance"
        }
    }

    /// The sentence under a map — what one tile's figure says.
    var explanation: LocalizedStringKey {
        switch self {
        case .autarky: "Share of consumption covered by your own energy"
        case .selfConsumption: "Share of production you used yourself"
        case .balance: "Production minus consumption, in kWh"
        }
    }

    /// The colour of the metric's chip. Purple and indigo as on the home card
    /// and the efficiency sheet; the balance takes the colour of its sunny
    /// side.
    var color: Color {
        switch self {
        case .autarky: .purple
        case .selfConsumption: .indigo
        case .balance: Self.surplusColor
        }
    }

    // The balance runs between the two colours the charts already use for
    // production and consumption: yellow where the roof made more than the
    // house used, teal where it was the other way round.
    private static let surplusColor = SerieColors.productionColor(useAlternativeColors: false)
    private static let deficitColor = SerieColors.consumptionColor(useAlternativeColors: false)

    /// The figure for one bucket: percent for the two shares, watt-hours for
    /// the balance. `nil` where it is undefined — no consumption to cover, no
    /// production to keep, or no energy at all.
    func value(of statistic: DayStatistic) -> Double? {
        switch self {
        case .autarky:
            statistic.autarky
        case .selfConsumption:
            statistic.selfConsumptionRate
        case .balance:
            statistic.production + statistic.consumption > 0
                ? statistic.production - statistic.consumption : nil
        }
    }

    /// The figure as written into a tile. The unit is not part of it; the
    /// shares get `unitSuffix`, the balance names its unit under the map.
    func text(for value: Double) -> String {
        switch self {
        case .autarky, .selfConsumption:
            return "\(Int(value.rounded()))"
        case .balance:
            let kilowattHours = Int((value / 1000).rounded())
            guard kilowattHours != 0 else { return "0" }
            // A real minus sign, not a hyphen — the same one the scale shows.
            return (kilowattHours > 0 ? "+" : "−") + "\(abs(kilowattHours))"
        }
    }

    var unitSuffix: String? {
        switch self {
        case .autarky, .selfConsumption: "%"
        case .balance: nil
        }
    }

    // Tiles stay translucent, like the fills of the intraday chart, so their
    // labels can stay in the primary colour in both appearances — and so a
    // weak day is pale rather than alarming.
    static let minimumTint = 0.06
    static let maximumTint = 0.55

    /// The fill for a tile holding `value`.
    ///
    /// The shares have a fixed scale, 0 to 100 %. The balance has none, so it
    /// is read against `strongest`, the largest surplus or deficit among the
    /// tiles on screen — by the square root, or the one evening the car
    /// charged would leave every other tile of the week blank.
    func fill(for value: Double, strongest: Double) -> Color {
        switch self {
        case .autarky, .selfConsumption:
            let share = min(max(value, 0), 100) / 100
            return color.opacity(
                Self.minimumTint + (Self.maximumTint - Self.minimumTint) * share
            )
        case .balance:
            guard strongest > 0 else { return Self.neutralColor }
            let share = min(abs(value) / strongest, 1).squareRoot()
            guard share > 0.08 else { return Self.neutralColor }
            let strength = 0.1 + (0.7 - 0.1) * share
            return (value > 0 ? Self.surplusColor : Self.deficitColor).opacity(strength)
        }
    }

    /// The largest magnitude among `values`, for metrics that scale to it.
    func strongest(among values: some Sequence<Double>) -> Double {
        values.map(abs).max() ?? 0
    }

    private static let neutralColor = Color.gray.opacity(0.14)

    /// The colours of the scale under a map, from its low end to its high.
    fileprivate var scaleColors: [Color] {
        switch self {
        case .autarky, .selfConsumption:
            [color.opacity(Self.minimumTint), color.opacity(Self.maximumTint)]
        case .balance:
            [Self.deficitColor.opacity(0.7), Self.neutralColor, Self.surplusColor.opacity(0.7)]
        }
    }

    fileprivate var scaleEnds: (low: String, high: String) {
        switch self {
        case .autarky, .selfConsumption: ("0%", "100%")
        case .balance: ("−", "+")
        }
    }
}

/// Chooses the metric a map shows.
struct MapMetricPicker: View {
    @Binding var metric: MapMetric

    var body: some View {
        HStack(spacing: 6) {
            ForEach(MapMetric.allCases) { option in
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
        }
    }
}

/// Reads a map's tint: which end is little, which is much — or, for the
/// balance, which is deficit and which surplus.
struct MapMetricScale: View {
    var metric: MapMetric

    var body: some View {
        HStack(spacing: 5) {
            Text(verbatim: metric.scaleEnds.low)
            Capsule()
                .fill(
                    LinearGradient(
                        colors: metric.scaleColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 44, height: 6)
            Text(verbatim: metric.scaleEnds.high)
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .fixedSize()
    }
}

/// The line under a map: what a tile's figure means, and how to read its
/// tint.
struct MapMetricCaption: View {
    var metric: MapMetric

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(metric.explanation)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            MapMetricScale(metric: metric)
        }
    }
}
