import Charts
import SwiftUI

struct OverviewChart: View {

    var consumption: MainData
    var batteries: [BatteryHistory] = []
    var isSmall: Bool = false
    var isAccent: Bool = false
    var showBatteryCharge: Bool = true
    var showBatteryDischange: Bool = true
    var showBatteryPercentage: Bool = true
    var useAlternativeColors: Bool = false

    var anyBatteryLevel: Bool {
        consumption.data.isEmpty == false && consumption.data.contains(where: { $0.batteryLevel != nil })
    }
    
    // Localized series labels using Text for proper .xcstrings support
    @Environment(\.locale) private var locale
    
    private func localizedString(_ key: String) -> String {
        // Force evaluation in current locale context
        let bundle = Bundle.main
        
        // Try to get the localized string
        if let path = bundle.path(forResource: locale.languageCode, ofType: "lproj"),
           let locBundle = Bundle(path: path) {
            return NSLocalizedString(key, bundle: locBundle, comment: "")
        }
        
        // Fallback to String(localized:)
        return String(localized: String.LocalizationValue(key))
    }
    
    private var productionLabel: String { localizedString("Production") }
    private var consumptionLabel: String { localizedString("Consumption") }
    private var batteryConsumptionLabel: String { localizedString("Battery consumption") }
    private var batteryChargedLabel: String { localizedString("Battery charged") }
    private var batteryLabel: String { localizedString("Battery") }

    var body: some View {
        VStack(spacing: 4) {
            Chart {

                ProductionConsumptionSeries(
                    data: consumption.data,
                    isAccent: isAccent,
                    useAlternativeColors: useAlternativeColors,
                    productionLabel: productionLabel,
                    consumptionLabel: consumptionLabel
                )

                if !batteries.isEmpty {
                    BatterySeries(
                        batteries: batteries,
                        isAccent: isAccent,
                        showCharging: showBatteryCharge,
                        showDischarging: showBatteryDischange,
                        batteryConsumptionLabel: batteryConsumptionLabel,
                        batteryChargedLabel: batteryChargedLabel
                    )
                }

                if showBatteryPercentage && anyBatteryLevel {
                    BatteryLevelSeries(
                        data: consumption.data,
                        maxY: getYMax(),
                        isAccent: isAccent,
                        batteryLabel: batteryLabel
                    )
                }

            }
            .chartYAxis {
                AxisMarks(preset: .automatic) { value in
                    AxisGridLine()
                        #if os(tvOS)
                            .foregroundStyle(.primary)
                        #endif

                    AxisValueLabel()
                        #if os(tvOS)
                            .foregroundStyle(.primary)
                        #endif
                }
            }
            .chartYAxisLabel {
                if !isSmall {
                    Text("kW")
                }
            }

            .chartYScale(domain: 0...getYMax())
            .chartXAxis {
                AxisMarks { value in
                    AxisGridLine()

                    AxisValueLabel(
                        format: .dateTime.hour(.twoDigits(amPM: .omitted)).minute(
                            .twoDigits
                        )
                    )
                    #if os(tvOS)
                        .font(.system(size: 18))
                    #endif
                }
            }
            #if os(watchOS)
            // Custom compact legend for watchOS
            .chartLegend(.hidden)
            #else
            .chartLegend(isSmall ? .hidden : .visible)
            .chartLegend(spacing: 4) // Reduce spacing between legend items
            #endif
            .chartForegroundStyleScale(
                [
                    productionLabel: SerieColors.productionColor(useAlternativeColors: useAlternativeColors),
                    consumptionLabel: SerieColors.consumptionColor(useAlternativeColors: useAlternativeColors),
                    (showBatteryDischange ? batteryConsumptionLabel : ""): (showBatteryDischange ? .indigo : .clear),
                    (showBatteryCharge ? batteryChargedLabel : ""): (showBatteryCharge ? .purple : .clear),
                    (showBatteryPercentage ? batteryLabel : ""):
                        (showBatteryPercentage
                        ? SerieColors.batteryLevelColor(useAlternativeColors: useAlternativeColors) : .clear),
                ]
            )
            
            // Custom compact legend for watchOS
            #if os(watchOS)
            if !isSmall {
                compactLegend
                    .padding(.top, 2)
            }
            #endif
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Compact Legend
    
    @ViewBuilder
    private var compactLegend: some View {
        LegendFlowLayout(spacing: 6) {
            LegendItem(
                color: SerieColors.productionColor(useAlternativeColors: useAlternativeColors),
                label: productionLabel
            )
            
            LegendItem(
                color: SerieColors.consumptionColor(useAlternativeColors: useAlternativeColors),
                label: consumptionLabel
            )
            
            if showBatteryDischange {
                LegendItem(color: .indigo, label: batteryConsumptionLabel)
            }
            
            if showBatteryCharge {
                LegendItem(color: .purple, label: batteryChargedLabel)
            }
            
            if showBatteryPercentage {
                LegendItem(
                    color: SerieColors.batteryLevelColor(useAlternativeColors: useAlternativeColors),
                    label: batteryLabel
                )
            }
        }
        .font(.system(size: 10, weight: .regular))
    }

    private func getTimeFormatter() -> DateFormatter {
        let result = DateFormatter()
        result.setLocalizedDateFormatFromTemplate("HH:mm")
        return result
    }

    private func getYMax() -> Double {
        let maxkW: Double? = consumption.data
            .map { Double(max($0.productionWatts, $0.consumptionWatts)) / 1000 }
            .max()

        guard let maxkW else { return 2.0 }

        return maxkW <= 0.005
            ? 2.0
            : maxkW * 1.1
    }

}

// MARK: - Compact Legend Components

/// A single legend item with a color dot and label
private struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 2) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
        }
    }
}

/// Simple flow layout for legend items
private struct LegendFlowLayout: Layout {
    var spacing: CGFloat = 6
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    // New line
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

#Preview("Normal") {
    OverviewChart(
        consumption: MainData.fake()
    )
}

#Preview("Small") {
    OverviewChart(
        consumption: MainData.fake(),
        batteries: BatteryHistory.fakeHistory(),
        isSmall: true
    )
    .frame(height: 80)
}

#Preview("Alternative Colors") {
    OverviewChart(
        consumption: MainData.fake(),
        batteries: BatteryHistory.fakeHistory(),
        isSmall: true,
        useAlternativeColors: true
    )
    .frame(height: 80)
}
