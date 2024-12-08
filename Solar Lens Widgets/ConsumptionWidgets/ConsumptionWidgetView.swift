import SwiftUI
import WidgetKit

struct ConsumptionWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) var renderingMode

    var entry: ConsumptionEntry

    var body: some View {
        let current = Double(entry.currentConsumption ?? 0) / 1000

        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack {
                    if entry.carCharging ?? false {
                        Image(systemName: "car.side")
                    } else {
                        Image(systemName: "house")
                    }

                    Text("\(String(format: "%.1f kW", current))")
                        .foregroundColor(
                            renderingMode == .fullColor ? .teal : .primary)
                }
            }
            .widgetLabel(getLabelText())
            .containerBackground(for: .widget) { Color.accentColor }

        case .accessoryCorner:
            Text("\(getText())")
            .foregroundColor(renderingMode == .fullColor ? .teal : .primary)
            .widgetCurvesContent()
            .widgetLabel {
                Text(getLabelText())
            }
            .containerBackground(for: .widget) { Color.accentColor }

        case .accessoryInline:
            HStack {
                if entry.carCharging ?? false {
                    Image(systemName: "car.side")
                        .symbolEffect(
                            .pulse.wholeSymbol, options: .repeat(.continuous))
                } else {
                    Image(systemName: "house")
                }
                Text("\(entry.currentConsumption ?? 0) W")
            }
            .containerBackground(for: .widget) { Color.accentColor }

        case .accessoryRectangular:
            HStack {
                if entry.carCharging ?? false {
                    Image(systemName: "car.side")
                        .symbolEffect(
                            .pulse.wholeSymbol, options: .repeat(.continuous))
                } else {
                    Image(systemName: "house")
                }
                Text("\(entry.currentConsumption ?? 0) W")
            }
            .containerBackground(for: .widget) { Color.accentColor }

        default:
            Image("AppIcon")
                .containerBackground(for: .widget) { Color.accentColor }
        }
    }

    private func getText() -> String {
        let current = Double(entry.currentConsumption ?? 0) / 1000

        var text =
            entry.isStaleData ?? false
            ? "?"
            : "\(String(format: "%.1f", current)) kW"
        
        if entry.carCharging ?? false {
            text += " 🚙"
        }

        return text
    }

    private func getLabelText() -> String {
        var text = ""
        if entry.consumptionFromSolar ?? 0 > 50 {
            let solarConsumption = Double(entry.consumptionFromSolar!) / 1000
            text = "☀️\(String(format: "%.1f", solarConsumption))"
        }

        if entry.consumptionFromBattery ?? 0 > 50 {
            let batteryConsumption =
                Double(entry.consumptionFromBattery!) / 1000
            text += "🔋\(String(format: "%.1f", batteryConsumption))"
        }

        if entry.consumptionFromGrid ?? 0 > 50 {
            let gridConsumption = Double(entry.consumptionFromGrid!) / 1000
            text += "🌐\(String(format: "%.1f", gridConsumption))"
        }

        return text
    }
}

struct ConsumptionWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview for circular
            ConsumptionWidgetView(
                entry: ConsumptionEntry(
                    date: Date(),
                    currentConsumption: 850,
                    carCharging: true,
                    consumptionFromSolar: 1100,
                    consumptionFromBattery: 300,
                    consumptionFromGrid: 100)
            )
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            .previewDisplayName("Circular")

            // Preview for inline
            ConsumptionWidgetView(
                entry: ConsumptionEntry(
                    date: Date(),
                    currentConsumption: 850,
                    carCharging: true,
                    consumptionFromSolar: 1100,
                    consumptionFromBattery: 300,
                    consumptionFromGrid: 100)
            )
            .previewContext(WidgetPreviewContext(family: .accessoryInline))
            .previewDisplayName("Inline")

            // Preview for corner
            ConsumptionWidgetView(
                entry: ConsumptionEntry(
                    date: Date(),
                    currentConsumption: 850,
                    carCharging: true,
                    consumptionFromSolar: 1100,
                    consumptionFromBattery: 300,
                    consumptionFromGrid: 100)
            )
            .previewContext(WidgetPreviewContext(family: .accessoryCorner))
            .previewDisplayName("Corner")
        }
    }
}
