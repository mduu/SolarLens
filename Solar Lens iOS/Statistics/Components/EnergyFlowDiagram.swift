import SwiftUI

/// Where a period's energy came from and where it went, as one picture.
///
/// Solar and grid import on the left, export and consumption on the right; the
/// width of each band is the energy that took that path. It answers the
/// question the four separate totals leave to mental arithmetic — how much of
/// what the roof made stayed in the house, and how much of what the house
/// used came from the roof.
///
/// The bands are ordered so they never cross: export sits above consumption on
/// the right because the exported share is drawn from the top of solar on the
/// left.
struct EnergyFlowDiagram: View {
    /// The period's totals, in watt-hours.
    var totals: DayStatistic

    @Environment(\.colorScheme) private var colorScheme

    private let solarColor = SerieColors.productionColor(useAlternativeColors: false)
    private let houseColor = SerieColors.consumptionColor(useAlternativeColors: false)
    private let importColor = StatisticsSeries.imported.color
    private let exportColor = StatisticsSeries.exported.color

    /// Space kept free on each side for a node's name and figure.
    private let labelWidth: CGFloat = 88
    private let nodeWidth: CGFloat = 7
    private let nodeGap: CGFloat = 16

    private var useMWh: Bool {
        max(totals.production, totals.consumption) >= 1_000_000
    }

    private func format(_ wattHours: Double) -> String {
        wattHours.formatWattHours(asMWh: useMWh, withUnit: true)
    }

    var body: some View {
        if totals.production + totals.consumption <= 0 {
            ContentUnavailableView(
                "No Data Available",
                systemImage: "arrow.triangle.branch",
                description: Text("Statistics will appear here when data is available.")
            )
            .frame(height: 250)
        } else {
            Canvas { context, size in
                draw(in: &context, size: size)
            }
            .frame(height: 200)
            .accessibilityElement()
            .accessibilityLabel(accessibilitySummary)
        }
    }

    private var accessibilitySummary: Text {
        Text("Solar") + Text(verbatim: " \(format(totals.production)), ")
            + Text("Import") + Text(verbatim: " \(format(totals.imported)), ")
            + Text("Consumption") + Text(verbatim: " \(format(totals.consumption)), ")
            + Text("Export") + Text(verbatim: " \(format(totals.exported))")
    }

    // MARK: - Drawing

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let production = max(0, totals.production)
        let consumption = max(0, totals.consumption)
        let imported = min(max(0, totals.imported), consumption)
        let exported = min(max(0, totals.exported), production)

        // With a battery the two ends of the solar band differ a little: what
        // left the roof for the house is not what the house drew from its own
        // supply that same period. The band simply tapers.
        let kept = production - exported
        let own = consumption - imported

        // A share too small to draw as a band is left out, node and all.
        let threshold = max(production + imported, consumption + exported) * 0.004
        let hasSolar = production > threshold
        let hasImport = imported > threshold
        let hasExport = exported > threshold
        let hasHouse = consumption > threshold

        let leftGap = hasSolar && hasImport ? nodeGap : 0
        let rightGap = hasExport && hasHouse ? nodeGap : 0
        let unit = min(
            (size.height - leftGap) / max(production + imported, 1),
            (size.height - rightGap) / max(consumption + exported, 1)
        )

        let left = labelWidth
        let right = size.width - labelWidth - nodeWidth

        // Left: solar on top — its exported share first — then grid import.
        let solarTop = 0.0
        let solarSplit = (hasExport ? exported : 0) * unit
        let solarBottom = production * unit
        let importTop = (hasSolar ? solarBottom + leftGap : 0)
        let importBottom = importTop + imported * unit

        // Right: export on top, then consumption — own supply first.
        let exportBottom = (hasExport ? exported : 0) * unit
        let houseTop = hasExport ? exportBottom + rightGap : 0
        let houseSplit = houseTop + own * unit
        let houseBottom = houseTop + consumption * unit

        func band(
            _ leftTop: Double, _ leftBottom: Double,
            _ rightTop: Double, _ rightBottom: Double,
            from: Color, to: Color
        ) {
            let start = left + nodeWidth
            let middle = (start + right) / 2
            var path = Path()
            path.move(to: CGPoint(x: start, y: leftTop))
            path.addCurve(
                to: CGPoint(x: right, y: rightTop),
                control1: CGPoint(x: middle, y: leftTop),
                control2: CGPoint(x: middle, y: rightTop)
            )
            path.addLine(to: CGPoint(x: right, y: rightBottom))
            path.addCurve(
                to: CGPoint(x: start, y: leftBottom),
                control1: CGPoint(x: middle, y: rightBottom),
                control2: CGPoint(x: middle, y: leftBottom)
            )
            path.closeSubpath()

            let strength = colorScheme == .dark ? 0.42 : 0.34
            context.fill(
                path,
                with: .linearGradient(
                    Gradient(colors: [from.opacity(strength), to.opacity(strength)]),
                    startPoint: CGPoint(x: start, y: 0),
                    endPoint: CGPoint(x: right, y: 0)
                )
            )
        }

        // A hair of surface between bands that share a node.
        if hasSolar && hasExport {
            band(solarTop, solarSplit - 1, 0, exportBottom - 1, from: solarColor, to: exportColor)
        }
        if hasSolar && hasHouse && kept > threshold {
            band(
                solarSplit + (hasExport ? 1 : 0), solarBottom,
                houseTop, houseSplit - (hasImport ? 1 : 0),
                from: solarColor, to: houseColor
            )
        }
        if hasImport && hasHouse {
            band(
                importTop, importBottom, houseSplit + (own > threshold ? 1 : 0), houseBottom,
                from: importColor, to: houseColor
            )
        }

        func node(_ x: Double, _ top: Double, _ bottom: Double, _ color: Color) {
            let rect = CGRect(x: x, y: top, width: nodeWidth, height: max(bottom - top, 2))
            context.fill(Path(roundedRect: rect, cornerRadius: 3), with: .color(color))
        }
        if hasSolar { node(left, solarTop, solarBottom, solarColor) }
        if hasImport { node(left, importTop, importBottom, importColor) }
        if hasExport { node(right, 0, exportBottom, exportColor) }
        if hasHouse { node(right, houseTop, houseBottom, houseColor) }

        // Labels sit beside their node's middle, pushed apart where two
        // slim nodes would otherwise stack their text on top of each other.
        func label(_ name: LocalizedStringKey, _ wattHours: Double, at y: Double, leading: Bool) {
            let x = leading ? left - 8 : right + nodeWidth + 8
            let anchor: UnitPoint = leading ? .trailing : .leading
            context.draw(
                Text(name).font(.caption).foregroundStyle(.secondary),
                at: CGPoint(x: x, y: y - 8), anchor: anchor
            )
            context.draw(
                Text(verbatim: format(wattHours)).font(.subheadline).fontWeight(.semibold),
                at: CGPoint(x: x, y: y + 9), anchor: anchor
            )
        }

        let (solarY, importY) = spread(
            (solarTop + solarBottom) / 2, (importTop + importBottom) / 2,
            both: hasSolar && hasImport, height: size.height
        )
        if hasSolar { label("Solar", production, at: solarY, leading: true) }
        if hasImport { label("Import", imported, at: importY, leading: true) }

        let (exportY, houseY) = spread(
            exportBottom / 2, (houseTop + houseBottom) / 2,
            both: hasExport && hasHouse, height: size.height
        )
        if hasExport { label("Export", exported, at: exportY, leading: false) }
        if hasHouse { label("Consumption", consumption, at: houseY, leading: false) }

        // The one ratio the picture is really about, on the band that shows it.
        if hasSolar, kept > threshold, min(solarBottom - solarSplit, houseSplit - houseTop) > 22,
            let rate = totals.selfConsumptionRate
        {
            let formatted = String(format: "%.0f", rate)
            context.draw(
                Text("\(formatted)% self-consumed")
                    .font(.caption2).fontWeight(.medium).foregroundStyle(.secondary),
                at: CGPoint(
                    x: (left + nodeWidth + right) / 2,
                    y: (solarSplit + solarBottom + houseTop + houseSplit) / 4
                )
            )
        }
    }

    /// Keeps two stacked labels inside the canvas and at least a label's
    /// height apart.
    private func spread(
        _ upper: Double, _ lower: Double, both: Bool, height: Double
    ) -> (Double, Double) {
        let inset = 17.0, minimumDistance = 38.0
        var first = min(max(upper, inset), height - inset)
        var second = min(max(lower, inset), height - inset)
        guard both, second - first < minimumDistance else { return (first, second) }

        let middle = (first + second) / 2
        first = middle - minimumDistance / 2
        second = middle + minimumDistance / 2
        if first < inset {
            second += inset - first
            first = inset
        }
        if second > height - inset {
            first -= second - (height - inset)
            second = height - inset
        }
        return (first, second)
    }
}

#if DEBUG
    #Preview("Year") {
        EnergyFlowDiagram(
            totals: DayStatistic(
                day: Date(), consumption: 10_300_000, production: 10_000_000,
                imported: 2_000_000, exported: 1_800_000
            )
        )
        .padding(.horizontal)
    }

    #Preview("Winter month") {
        EnergyFlowDiagram(
            totals: DayStatistic(
                day: Date(), consumption: 830_000, production: 280_000,
                imported: 550_000, exported: 0
            )
        )
        .padding(.horizontal)
    }
#endif
