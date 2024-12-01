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
                    Image("32px")
                } else {
                    Image("smalltrans")
                }
            }
            
        case .accessoryCircular:

            ZStack {
                AccessoryWidgetBackground()
                if renderingMode == .fullColor {
                    Image("solarlens")
                } else {
                    Image("solarlenstrans")
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
