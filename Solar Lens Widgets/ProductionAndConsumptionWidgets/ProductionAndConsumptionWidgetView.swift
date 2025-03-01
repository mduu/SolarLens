import SwiftUI
import WidgetKit

struct ProductionAndConsumptionWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) var renderingMode
    @Environment(\.showsWidgetLabel) private var showsWidgetLabel

    var entry: ProductionAndConsumptionEntry

    var body: some View {
        let current = Double(entry.currentProduction ?? 0) / 1000
        let max = Double(entry.maxProduction ?? 0) / 1000

        switch family {

        case .accessoryCircular:

            ZStack {
                AccessoryWidgetBackground()

                Gauge(
                    value: current,
                    in: 0...max
                ) {
                    Image(systemName: "sun.max")
                } currentValueLabel: {
                    Text("\(String(format: "%.1f kW", current))")
                }
                .gaugeStyle(.circular)
                .tint(renderingMode == .fullColor ? getGaugeStyle() : nil)
                .widgetLabel {
                    Text(getLabelText())
                }  // :widgetLabel

            }  // :ZStack
            .containerBackground(for: .widget) { Color.accentColor }

        case .accessoryCorner:

            Text("\(String(format: "%.1f kW", current))")
                .foregroundColor(
                    renderingMode == .fullColor
                        ? current >= 0.1 ? .accent : .gray
                        : nil
                )
                .widgetCurvesContent()
                .widgetLabel {
                    Text(getLabelText())
                }  // :widgetLabel
                .containerBackground(for: .widget) { Color.accentColor }

        default:
            Image("AppIcon")
                .containerBackground(for: .widget) { Color.accentColor }
        }
    }

    private func getLabelText() -> String {
        var text = ""

        if entry.toBattery ?? 0 > 10 {
            let toBattery =
                Double(entry.toBattery!) / 1000
            text += "🔋\(String(format: "%.1f", toBattery))"
        } else if entry.toBattery ?? 0 <= 0 && entry.fromBattery ?? 0 > 0 {
            let fromBattery =
                Double(entry.fromBattery!) / 1000
            text += "🔋 -\(String(format: "%.1f", fromBattery))"
        }

        if entry.toHouse ?? 0 > 10 {
            let toHouse = Double(entry.toHouse!) / 1000
            text += "🏠\(String(format: "%.1f", toHouse))"
        }

        if entry.toGrid ?? 0 > 10 {
            let toGrid = Double(entry.toGrid!) / 1000
            text += "🌐\(String(format: "%.1f", toGrid))"
        } else if entry.toGrid ?? 0 <= 0 && entry.fromGrid ?? 0 > 0 {
            let fromGrid = Double(entry.fromGrid!) / 1000
            text += "🌐 -\(String(format: "%.1f", fromGrid))"
        }

        if entry.carCharging ?? false {
            text += " 🚙"
        }

        return text
    }

    func getGaugeStyle() -> Gradient {
        return entry.currentProduction ?? 0 < 50
            ? Gradient(colors: [.gray, .gray])
            : Gradient(colors: [.blue, .yellow, .orange])
    }
}

struct ProductionAndConsumptionWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview for circular
            ProductionAndConsumptionWidgetView(
                entry: ProductionAndConsumptionEntry.previewData()
            )
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            .previewDisplayName("Circular")

            #if os(watchOS)

                // Preview for corner
                ProductionAndConsumptionWidgetView(
                    entry: ProductionAndConsumptionEntry.previewData()
                )
                .previewContext(WidgetPreviewContext(family: .accessoryCorner))
                .previewDisplayName("Corner")

                // Preview for corner
                ProductionAndConsumptionWidgetView(
                    entry: ProductionAndConsumptionEntry.previewDataBatteryOnly()
                )
                .previewContext(WidgetPreviewContext(family: .accessoryCorner))
                .previewDisplayName("Corner bat. only")
            #endif
        }
    }
}
