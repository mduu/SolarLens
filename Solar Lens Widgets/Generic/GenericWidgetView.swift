import SwiftUI
import WidgetKit

struct GenericWidgetView: View {
    var entry: GenericEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image("small")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 36, height: 36) // Adjust the size as needed
                .clipShape(Circle()) // Mask the image into a circular shape
        }
    }
}

#Preview {
    GenericWidgetView(
        entry: .previewData()
    )
}
