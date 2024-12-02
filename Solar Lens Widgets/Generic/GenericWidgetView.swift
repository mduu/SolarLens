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
            }
            
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
            }

        default:
            Text("unknown")
        }
    }
}

#Preview("FullColor") {
    GenericWidgetView(
        entry: .previewData()
    )
}

#Preview("Accented") {
    GenericWidgetView(
        entry: .previewData()
    ).environment(\.widgetRenderingMode, .accented)
}
