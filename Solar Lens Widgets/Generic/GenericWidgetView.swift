import SwiftUI
import WidgetKit

struct GenericWidgetView: View {
    @Environment(\.widgetRenderingMode) var renderingMode
    @Environment(\.widgetFamily) private var family

    var entry: GenericEntry

    var body: some View {
        switch family {
        case .accessoryCorner:

            ZStack {
                AccessoryWidgetBackground()
                if renderingMode == .fullColor {
                    Image("solarlens")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image("smalltrans")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }.containerBackground(for: .widget) { Color.accentColor }
            
        case .accessoryCircular:

            ZStack {
                AccessoryWidgetBackground()
                if renderingMode == .fullColor {
                    Image("solarlens")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image("solarlenstrans")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }.containerBackground(for: .widget) { Color.accentColor }

        default:
            Text("unknown")
                .containerBackground(for: .widget) { Color.accentColor }
        }
    }
}

struct GenericWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview for circular
            GenericWidgetView(
                entry: GenericEntry(
                    date: Date())
            )
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            .previewDisplayName("Circular")

            // Preview for circular
            GenericWidgetView(
                entry: GenericEntry(
                    date: Date())
            )
            .environment(\.widgetRenderingMode, .accented)
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            .previewDisplayName("Circular Accented")

            // Preview for corner
            GenericWidgetView(
                entry: GenericEntry(
                    date: Date())
            )
            .previewContext(WidgetPreviewContext(family: .accessoryCorner))
            .previewDisplayName("Corner")
        }
    }
}
