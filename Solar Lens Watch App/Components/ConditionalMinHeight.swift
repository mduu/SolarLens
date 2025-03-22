import SwiftUI

struct ConditionalMinHeight: ViewModifier {
    let minHeightSmallWatch: CGFloat
    let minHeightLargeWatch: CGFloat

    func body(content: Content) -> some View {
        let isLargeWatch =
            WKInterfaceDevice.current().screenBounds.height >= 220  // 45mm watches logical height

        if isLargeWatch {
            content.frame(minHeight: minHeightLargeWatch)
        } else {
            content.frame(minHeight: minHeightSmallWatch)
        }
    }
}
