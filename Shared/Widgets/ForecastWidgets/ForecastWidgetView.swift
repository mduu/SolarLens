import SwiftUI
import WidgetKit

struct ForecastWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) var renderingMode
    @Environment(\.showsWidgetLabel) private var showsWidgetLabel

    var entry: ForecastEntry

    var body: some View {
        let forecast = entry.displayedForecast
        let expected = forecast?.expected ?? 0
        let gaugeMax = entry.gaugeMax
        let label = entry.dayLabel

        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()

                if showsWidgetLabel {
                    ZStack {
                        AccessoryWidgetBackground()
                        if renderingMode == .fullColor {
                            Image("solarlens")
                        } else {
                            Image("solarlenstrans")
                        }
                    }
                    .widgetLabel {
                        if let label {
                            Text("⛅ \(String(format: "%.0f", expected)) kWh \(label)")
                        } else {
                            Text("⛅ \(String(format: "%.0f", expected)) kWh")
                        }
                    }
                } else {
                    Gauge(
                        value: expected,
                        in: 0...gaugeMax
                    ) {
                        Image(systemName: "sun.horizon")
                    } currentValueLabel: {
                        Text("\(String(format: "%.0f", expected))")
                    }
                    #if os(watchOS)
                        .gaugeStyle(.circular)
                    #else
                        .gaugeStyle(.accessoryCircular)
                    #endif
                    .tint(renderingMode == .fullColor ? getGaugeTint() : nil)
                }
            }
            .containerBackground(for: .widget) { Color.accent }

        #if os(watchOS)
            case .accessoryCorner:
                HStack(spacing: 2) {
                    Text("\(String(format: "%.0f", expected)) kWh")
                    if let label {
                        Text(label)
                    }
                }
                .foregroundColor(
                    renderingMode == .fullColor
                        ? expected > 0 ? .accent : .gray
                        : nil
                )
                .widgetCurvesContent()
                .widgetLabel {
                    Gauge(
                        value: expected,
                        in: 0...gaugeMax
                    ) {
                        Text("kWh")
                    } currentValueLabel: {
                        Text("\(String(format: "%.0f", expected))")
                    } minimumValueLabel: {
                        Text("0")
                    } maximumValueLabel: {
                        Text("\(String(format: "%.0f", gaugeMax))")
                    }
                    .gaugeStyle(.automatic)
                    .tint(renderingMode == .fullColor ? getGaugeTint() : nil)
                }
                .containerBackground(for: .widget) { Color.accentColor }
        #endif

        case .accessoryInline:
            if let label {
                Text("⛅ \(String(format: "%.0f", expected)) kWh \(label)")
            } else {
                Text("⛅ \(String(format: "%.0f", expected)) kWh")
            }

        default:
            Image("AppIcon")
                .containerBackground(for: .widget) { Color.accentColor }
        }
    }

    func getGaugeTint() -> Gradient {
        return entry.displayedForecast == nil
            ? Gradient(colors: [.gray, .gray])
            : Gradient(colors: [.blue, .yellow, .orange])
    }
}

struct ForecastWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ForecastWidgetView(
                entry: ForecastEntry.previewData()
            )
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            .previewDisplayName("Circular (Day)")

            ForecastWidgetView(
                entry: ForecastEntry.previewDataNight()
            )
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            .previewDisplayName("Circular (Night)")

            #if os(watchOS)
                ForecastWidgetView(
                    entry: ForecastEntry.previewData()
                )
                .previewContext(WidgetPreviewContext(family: .accessoryCorner))
                .previewDisplayName("Corner")
            #endif

            ForecastWidgetView(
                entry: ForecastEntry.previewData()
            )
            .previewContext(WidgetPreviewContext(family: .accessoryInline))
            .previewDisplayName("Inline")

            ForecastWidgetView(
                entry: ForecastEntry.previewDataNight()
            )
            .previewContext(WidgetPreviewContext(family: .accessoryInline))
            .previewDisplayName("Inline (Night)")
        }
    }
}
