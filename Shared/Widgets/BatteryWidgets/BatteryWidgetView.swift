import SwiftUI
import WidgetKit

struct BatteryWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) var renderingMode
    @Environment(\.showsWidgetLabel) private var showsWidgetLabel

    var entry: BatteryEntry

    var body: some View {

        switch family {
        case .accessoryCircular, .systemMedium, .systemSmall:
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
                        Text(
                            "🔋\(String(describing: entry.currentBatteryLevel ?? 0)) %"
                        )
                    }

                } else {

                    ProgressView(
                        value: Double(entry.currentBatteryLevel ?? 0),
                        total: 100
                    ) {
                    } currentValueLabel: {

                        VStack(spacing: 0) {
                            Text(
                                "\(String(describing: entry.currentBatteryLevel ?? 0))%"
                            )
                            .foregroundColor(
                                entry.currentBatteryChargeRate ?? 0 < 0
                                    && renderingMode == .fullColor
                                    ? .orange
                                    : nil)

                            if entry.currentBatteryChargeRate ?? 0 > 0 {
                                Image(systemName: "bolt.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 10)
                            }
                        }

                    }
                    .progressViewStyle(CircularProgressViewStyle())
                    .tint(
                        renderingMode == .fullColor
                            ? Gradient(colors: [getColor()])
                            : nil)

                }
            }
            .containerBackground(for: .widget) { Color.accentColor }

        #if os(watchOS)
            case .accessoryCorner:
                Text("\(String(describing: entry.currentBatteryLevel ?? 0))%")
                    .foregroundColor(renderingMode == .fullColor ? .green : nil)
                    .widgetCurvesContent()
                    .widgetLabel {
                        ProgressView(
                            value: Double(entry.currentBatteryLevel ?? 0),
                            total: 100
                        ) {
                            Image(systemName: GetBatterySymbolName())
                        } currentValueLabel: {
                            Text(
                                "\(String(describing: entry.currentBatteryLevel ?? 0)) %"
                            )
                        }
                        .progressViewStyle(CircularProgressViewStyle())
                        .tint(renderingMode == .fullColor ? getColor() : nil)

                    }
                    .containerBackground(for: .widget) { Color.accentColor }
        #endif

        case .accessoryInline:
            let charging = Double(entry.currentBatteryChargeRate ?? 0) / 1000
            HStack {
                Image(systemName: GetBatterySymbolName())
                Text(
                    "\(entry.currentBatteryLevel ?? 0)%  \(String(format: "+%.1f", charging)) kW"
                )
            }
            .containerBackground(for: .widget) { Color.accentColor }

        default:
            Image("AppIcon")
                .containerBackground(for: .widget) { Color.accentColor }
        }
    }

    private func GetBatterySymbolName() -> String {
        (entry.currentBatteryChargeRate ?? 0) > 0
            ? "bolt.fill"
            : "battery.100percent"
    }

    private func getColor() -> Color {
        entry.currentBatteryLevel ?? 0 < 10
            ? .red
            : .green
    }
}

struct BatteryWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview for circular
            BatteryWidgetView(
                entry: BatteryEntry(
                    date: Date(),
                    currentBatteryLevel: 60,
                    currentBatteryChargeRate: -1234)
            )
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            .previewDisplayName("Circular")

            // Preview for circular
            BatteryWidgetView(
                entry: BatteryEntry(
                    date: Date(),
                    currentBatteryLevel: 60,
                    currentBatteryChargeRate: 1234)
            )
            .previewContext(
                WidgetPreviewContext(family: .accessoryCircular)
            )
            .previewDisplayName("Circular Accent")
            .environment(\.widgetRenderingMode, .accented)

            // Preview for circular
            BatteryWidgetView(
                entry: BatteryEntry(
                    date: Date(),
                    currentBatteryLevel: 60,
                    currentBatteryChargeRate: 1345)
            )
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            .previewDisplayName("Charging")

            // Preview for inline
            BatteryWidgetView(
                entry: BatteryEntry(
                    date: Date(),
                    currentBatteryLevel: 60,
                    currentBatteryChargeRate: 1234)
            )
            .previewContext(WidgetPreviewContext(family: .accessoryInline))
            .previewDisplayName("Inline")

            #if os(watchOS)
                // Preview for corner
                BatteryWidgetView(
                    entry: BatteryEntry(
                        date: Date(),
                        currentBatteryLevel: 60,
                        currentBatteryChargeRate: 1234)
                )
                .previewContext(WidgetPreviewContext(family: .accessoryCorner))
                .previewDisplayName("Corner")
            #endif
            
            #if os(iOS)
            // Preview for corner
            BatteryWidgetView(
                entry: BatteryEntry(
                    date: Date(),
                    currentBatteryLevel: 60,
                    currentBatteryChargeRate: 1234)
            )
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("System Med.")
            
            // Preview for corner
            BatteryWidgetView(
                entry: BatteryEntry(
                    date: Date(),
                    currentBatteryLevel: 60,
                    currentBatteryChargeRate: 1234)
            )
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("System Med.")
            #endif
        }
    }
}
