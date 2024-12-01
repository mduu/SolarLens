import SwiftUI
import WidgetKit

struct GenericWidgetView: View {
    @Environment(\.widgetRenderingMode) var renderingMode
    var entry: GenericEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            if renderingMode == .fullColor {
                Image("solarlens")
            } else {
                Image("solarlenstrans")
            }
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
