import SwiftUI

struct ConditionalMaxFrame: ViewModifier {
    let maxWidthSmallWatch: CGFloat
    let maxHeightSmallWatch: CGFloat
    let maxWidthLargeWatch: CGFloat
    let maxHeightLargeWatch: CGFloat

    func body(content: Content) -> some View {
        let isLargeWatch =
            WKInterfaceDevice.current().screenBounds.height >= 220  // 45mm watches logical height

        if isLargeWatch {
            content
                .frame(
                    maxWidth: maxWidthLargeWatch,
                    maxHeight: maxHeightLargeWatch
                )
        } else {
            content
                .frame(
                    maxWidth: maxWidthSmallWatch,
                    maxHeight: maxHeightSmallWatch
                )
        }
    }
}
