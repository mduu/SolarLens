import SwiftUI
import WidgetKit

struct EfficiencyWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) var renderingMode
    @Environment(\.showsWidgetLabel) private var showsWidgetLabel

    var entry: EfficiencyEntry

    var body: some View {

        switch family {
        #if os(iOS)
            case .systemSmall, .systemMedium:
                ZStack {
                    AccessoryWidgetBackground()

                    EfficiencyInfoView(
                        todaySelfConsumptionRate: entry.selfConsumption,
                        todayAutarchyDegree: entry.autarky,
                        showLegend: family == .systemMedium,
                        showTitle: false
                    )
                }
                .containerBackground(for: .widget) { }
        #endif
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()

                if showsWidgetLabel {

                    ZStack {
                        AccessoryWidgetBackground()

                        EfficiencyInfoView(
                            todaySelfConsumptionRate: entry.selfConsumption,
                            todayAutarchyDegree: entry.autarky,
                            showLegend: false,
                            showTitle: false
                        )

                    }
                    .widgetLabel {
                        Text(
                            "♻️ \(String(describing: entry.selfConsumption?.formatIntoPercentage())), 🍃 \(String(describing: entry.autarky.formatIntoPercentage()))"
                        )
                    }

                } else {

                    EfficiencyInfoView(
                        todaySelfConsumptionRate: entry.selfConsumption,
                        todayAutarchyDegree: entry.autarky,
                        showLegend: false,
                        showTitle: false
                    )

                }
            }
            .containerBackground(for: .widget) {}

        case .accessoryInline:
            HStack {
                Text(
                    "♻️ \(entry.selfConsumption?.formatIntoPercentage() ?? ""), 🍃 \(String(describing: entry.autarky.formatIntoPercentage()))"
                )
            }
            .containerBackground(for: .widget) { Color.accentColor }

        default:
            Image("AppIcon")
                .containerBackground(for: .widget) { Color.accentColor }
        }
    }
}

struct EfficiencyWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview for circular
            EfficiencyWidgetView(
                entry: EfficiencyEntry(
                    date: Date(),
                    selfConsumption: 60,
                    autarky: 87
                )
            )
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            .previewDisplayName("Circular")

            // Preview for circular Accent
            EfficiencyWidgetView(
                entry: EfficiencyEntry(
                    date: Date(),
                    selfConsumption: 60,
                    autarky: 87
                )
            )
            .previewContext(
                WidgetPreviewContext(family: .accessoryCircular)
            )
            .previewDisplayName("Circular Accent")
            .environment(\.widgetRenderingMode, .accented)

            // Preview for circular Vibrant
            EfficiencyWidgetView(
                entry: EfficiencyEntry(
                    date: Date(),
                    selfConsumption: 60,
                    autarky: 87
                )
            )
            .previewContext(
                WidgetPreviewContext(family: .accessoryCircular)
            )
            .previewDisplayName("Circ. Vibrant 100%")
            .environment(\.widgetRenderingMode, .vibrant)

            // Preview for circular 100%
            EfficiencyWidgetView(
                entry: EfficiencyEntry(
                    date: Date(),
                    selfConsumption: 100,
                    autarky: 100
                )
            )
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            .previewDisplayName("Full")

            // Preview for inline
            EfficiencyWidgetView(
                entry: EfficiencyEntry(
                    date: Date(),
                    selfConsumption: 60,
                    autarky: 87
                )
            )
            .previewContext(WidgetPreviewContext(family: .accessoryInline))
            .previewDisplayName("Inline")

            #if os(iOS)
                // Preview for systemSmall
                EfficiencyWidgetView(
                    entry: EfficiencyEntry(
                        date: Date(),
                        selfConsumption: 60,
                        autarky: 87
                    )
                )
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Sys. Small")
            #endif

            #if os(iOS)
                // Preview for systemMedium
                EfficiencyWidgetView(
                    entry: EfficiencyEntry(
                        date: Date(),
                        selfConsumption: 60,
                        autarky: 87
                    )
                )
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Sys. Med.")
            #endif
        }
    }
}
