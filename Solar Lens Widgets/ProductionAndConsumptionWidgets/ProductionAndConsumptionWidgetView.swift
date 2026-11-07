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
                    Text("\("\(current.localized(decimals: 1)) kW")")
                }
                .gaugeStyle(.circular)
                .tint(renderingMode == .fullColor ? getGaugeStyle() : nil)
                .widgetLabel {
                    Text(getLabelText())
                }  // :widgetLabel

            }  // :ZStack
            .containerBackground(for: .widget) { Color.accentColor }

        case .accessoryCorner:

            Text("\("\(current.localized(decimals: 1)) kW")")
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
        
        if entry.toHouse ?? 0 > 10 {
            let toHouse = Double(entry.toHouse!) / 1000
            text += "🏠\(toHouse.localized(decimals: 1))"
        }

        if entry.toBattery ?? 0 > 10 {
            let toBattery =
                Double(entry.toBattery!) / 1000
            text += "🔋\(toBattery.localized(decimals: 1))"
        } else if entry.fromBattery ?? 0 > 10 {
            let fromBattery =
                Double(entry.fromBattery!) / 1000
            text += "🔋 -\(fromBattery.localized(decimals: 1))"
        }

        if entry.toGrid ?? 0 > 10 {
            let toGrid = Double(entry.toGrid!) / 1000
            text += "🌐\(toGrid.localized(decimals: 1))"
        } else if entry.fromGrid ?? 0 > 10 {
            let fromGrid = Double(entry.fromGrid!) / 1000
            text += "🌐 -\(fromGrid.localized(decimals: 1))"
        }

        if entry.carCharging ?? false {
            text += " 🚙"
        }
        
        return text == "" ? " " : text
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
